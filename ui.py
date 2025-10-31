import gradio as gr
import webbrowser
import threading
import time
from agent.agent import run_task
import tempfile
import json
import os
import sys
import subprocess
import re
from io import StringIO


def find_ollama_executable():
    """Find the Ollama executable on Windows."""
    # Common installation paths
    possible_paths = [
        r"C:\Program Files\Ollama\ollama.exe",
        r"C:\Program Files (x86)\Ollama\ollama.exe",
        os.path.expanduser(r"~\AppData\Local\Programs\Ollama\ollama.exe"),
        os.path.expanduser(r"~\AppData\Local\Ollama\ollama.exe"),
    ]
    
    for path in possible_paths:
        if os.path.exists(path):
            print(f"Found Ollama at: {path}")
            return path
    
    # Try system PATH
    return "ollama"


def get_local_ollama_models():
    """Fetch list of locally available Ollama models."""
    try:
        ollama_cmd = find_ollama_executable()
        
        # Use PowerShell to run ollama list (more reliable on Windows)
        result = subprocess.run(
            ["powershell", "-Command", f'& "{ollama_cmd}" list'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        print(f"Ollama command return code: {result.returncode}")
        
        if result.returncode != 0:
            print(f"Ollama stderr: {result.stderr}")
            print("Ollama command failed, using fallback")
            return ["qwen3-coder:30b", "qwen2.5-coder:1.5b", "llama3.1:latest", "phi3.5:latest"]
        
        # Parse output: each line has format "NAME    ID    SIZE    MODIFIED"
        models = []
        lines = result.stdout.split('\n')
        
        for i, line in enumerate(lines):
            if i == 0:  # Skip header
                continue
            line = line.strip()
            if line:
                # Extract model name (first column)
                parts = line.split()
                if parts:
                    model_name = parts[0]
                    models.append(model_name)
        
        if models:
            print(f"✓ Found {len(models)} Ollama models: {models}")
            return models
        else:
            print("No models found, using defaults")
            return ["qwen3-coder:30b", "qwen2.5-coder:1.5b", "llama3.1:latest", "phi3.5:latest"]
    
    except Exception as e:
        print(f"Error fetching Ollama models: {e}")
        return ["qwen3-coder:30b", "qwen2.5-coder:1.5b", "llama3.1:latest", "phi3.5:latest"]


def update_model_in_file(model_name):
    """Update the MODEL_NAME in agent/models.py file."""
    try:
        models_file = "agent/models.py"
        
        with open(models_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace MODEL_NAME value using regex
        updated_content = re.sub(
            r'MODEL_NAME\s*=\s*["\'].*?["\']',
            f'MODEL_NAME = "{model_name}"',
            content
        )
        
        with open(models_file, 'w', encoding='utf-8') as f:
            f.write(updated_content)
        
        return True
    except Exception as e:
        print(f"Error updating models.py: {e}")
        return False


# Auto-open browser
def open_browser(link):
    time.sleep(1)
    webbrowser.open(link)


def run_agent(natural_prompt, selected_model, progress=gr.Progress()):
    """Run the agent with real-time progress updates."""
    
    # Update the model in models.py file
    update_model_in_file(selected_model)
    
    # Reload the models module to pick up the change
    import agent.models as models
    import importlib
    importlib.reload(models)
    
    progress(0, desc=" Starting agent...")
    
    task = {"instruction": natural_prompt}

    # Save task to temp JSON for agent
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix=".json") as tmp:
        json.dump(task, tmp)
        tmp_path = tmp.name

    output_buffer = []
    stage_map = {
        "Generating tests": (0.1, " Generating test cases"),
        "Generating initial code": (0.2, " Writing initial implementation"),
        "Attempt 1": (0.3, " Running tests - Attempt 1"),
        "Attempt 2": (0.5, " Running tests - Attempt 2"),
        "Attempt 3": (0.7, " Running tests - Attempt 3"),
        "Tests passed": (0.75, " Tests passed!"),
        "Running dependency audit": (0.8, " Auditing dependencies"),
        "Running security scan": (0.85, " Scanning code security"),
        "Running mutation testing": (0.9, " Running mutation tests"),
        "Task complete": (1.0, " Complete!")
    }

    original_print = print

    def patched_print(*args, **kwargs):
        msg = " ".join(str(a) for a in args)
        output_buffer.append(msg)
        
        # Update progress based on stage
        for keyword, (prog_val, desc) in stage_map.items():
            if keyword in msg:
                progress(prog_val, desc=desc)
                break
        
        original_print(*args, **kwargs)

    # Monkey-patch print
    import builtins
    builtins.print = patched_print

    try:
        run_task(tmp_path)
    except Exception as e:
        output_buffer.append(f"\n Error: {e}")
        import traceback
        output_buffer.append(traceback.format_exc())
    finally:
        # Restore original print
        builtins.print = original_print
        try:
            os.unlink(tmp_path)
        except PermissionError:
            pass

    return "\n".join(output_buffer)


# Get available models
AVAILABLE_MODELS = get_local_ollama_models()

# UI Layout
with gr.Blocks(theme="soft", title="AI Code Agent") as ui:
    gr.Markdown(
        """
        <div style="text-align:center; margin-top:-20px;">
            <h1> AI Code Agent</h1>
            <p>Automated code generation, testing, and security validation</p>
        </div>
        """
    )

    with gr.Row():
        with gr.Column(scale=2):
            gr.Markdown("###  Task Configuration")
            
            prompt = gr.Textbox(
                placeholder="E.g., 'Write a function to check if a number is prime'",
                label="Task Description",
                lines=4
            )
            
            model_dropdown = gr.Dropdown(
                choices=AVAILABLE_MODELS,
                value=AVAILABLE_MODELS[0] if AVAILABLE_MODELS else "qwen3-coder:30b",
                label=" Select Model",
                info="Locally available Ollama models"
            )
            
            model_status = gr.Textbox(value="", label="Model status", interactive=False, lines=1)
            
            refresh_btn = gr.Button(" Refresh Models", size="sm")
            
            run_button = gr.Button("▶ Run Agent", variant="primary", size="lg")

        with gr.Column(scale=3):
            gr.Markdown("###  Execution Log")
            
            output = gr.Textbox(
                label="Real-time Output",
                lines=22,
                interactive=False,
                show_label=False
            )

    with gr.Accordion(" Task History", open=False):
        history = gr.JSON(label="Previous Runs")

    def select_model(model):
        """Handler when user selects a model from the dropdown.

        Immediately update agent/models.py and report status.
        """
        ok = update_model_in_file(model)
        return f"Model set to: {model}" if ok else "Failed to update model"


    def launch_task(text, model, old_history):
        if not text.strip():
            return " Please enter a task description", old_history
        
        # Update models.py with selected model
        if update_model_in_file(model):
            result = run_agent(text, model)
        else:
            result = " Failed to update model configuration"
        
        new_entry = {
            "task": text,
            "model": model,
            "output": result[:500] + "..." if len(result) > 500 else result
        }
        return result, [new_entry] + (old_history or [])
    
    def refresh_models():
        """Refresh the list of available models and update the dropdown."""
        models = get_local_ollama_models()
        return gr.update(choices=models, value=models[0] if models else None)

    run_button.click(
        launch_task,
        inputs=[prompt, model_dropdown, history],
        outputs=[output, history]
    )
    
    # Update model immediately when user selects from dropdown
    model_dropdown.change(
        select_model,
        inputs=[model_dropdown],
        outputs=[model_status]
    )

    refresh_btn.click(
        refresh_models,
        outputs=[model_dropdown]
    )
    
    # Add examples
    gr.Examples(
        examples=[
            "Write a function to calculate fibonacci numbers",
            "Create a function that validates email addresses",
            "Implement a binary search algorithm"
        ],
        inputs=prompt,
        label=" Example Prompts"
    )

# Launch browser
threading.Thread(target=open_browser, args=("http://127.0.0.1:7860",), daemon=True).start()

ui.launch()

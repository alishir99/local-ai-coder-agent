# Quick Start Guide

Get up and running with AI Code Agent in under 5 minutes!

##  Installation

### Option 1: Automated Install (Recommended)

**Windows:**
```batch
install_windows.bat
```

**macOS/Linux:**
```bash
chmod +x install_mac.sh    # or install_linux.sh
./install_mac.sh
```

### Option 2: Manual Install

```bash
# 1. Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Install Ollama and pull a model
# Download from: https://ollama.com
ollama pull qwen2.5-coder:1.5b

# 4. Build Docker sandbox
docker build -t ai-agent-python .
```

##  First Run

### Web Interface (Recommended)

```bash
python ui.py
```

Then open: http://127.0.0.1:7860

### Command Line

```bash
python -m agent.agent examples/fizzbuzz.json
```

##  Your First Task

### In the Web UI:

1. **Enter a task:**
   ```
   Write a function to calculate the factorial of a number
   ```

2. **Select a model:**
   - `qwen2.5-coder:1.5b` - Fast, good for simple tasks
   - `phi3.5` - Balanced performance
   - `llama3.1` - Better reasoning

3. **Click "Run Agent"** and watch the magic! 

### From Command Line:

Create `my_task.json`:
```json
{
  "description": "Write a function to calculate factorial",
  "signature": "def factorial(n: int) -> int:",
  "examples": "factorial(5) -> 120"
}
```

Run:
```bash
python -m agent.agent my_task.json
```

##  What Happens?

The agent will:
1.  Generate comprehensive tests
2.  Write the implementation
3.  Run tests and fix errors (auto-retry up to 3x)
4.  Scan for vulnerable dependencies
5.  Check for security issues
6.  Run mutation tests for quality

##  Example Tasks to Try

**Easy:**
- "Write a function to check if a string is a palindrome"
- "Implement a function to find the maximum element in a list"

**Medium:**
- "Create a function to validate email addresses with regex"
- "Implement binary search algorithm"

**Advanced:**
- "Write a function to generate the nth Fibonacci number using memoization"
- "Implement a basic LRU cache with size limit"

##  Customization

### Change Model Mid-Session
Just select a different model from the dropdown and click refresh!

### Adjust Timeout
Edit `agent/agent.py`:
```python
DEFAULT_TIMEOUT = 120  # seconds
```

### Add More Models
```bash
ollama pull codellama:13b
ollama pull deepseek-coder:6.7b
```

##  Troubleshooting

**Docker not running:**
```bash
# Start Docker Desktop, then retry
docker ps
```

**Ollama not found:**
```bash
# Verify installation
ollama --version
ollama list
```

**Port 7860 in use:**
Edit `ui.py` and change:
```python
ui.launch(server_port=7861)
```

##  Next Steps

- Check out `examples/` directory for more tasks
- Read the full [README.md](README.md)
- Explore the codebase in `agent/`
- Contribute! See [CONTRIBUTING.md](CONTRIBUTING.md)

##  Learn More

- [Ollama Models](https://ollama.com/library)
- [Gradio Documentation](https://gradio.app/docs)
- [Mutation Testing Guide](https://mutmut.readthedocs.io/)

---

**Having issues?** Open an issue on GitHub with details!

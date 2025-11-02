import json
from litellm import completion

# Default model (you can change this later to experiment)
MODEL_NAME = "qwen2.5-coder:1.5b"


def call_model(system_prompt, user_message, temperature=0.2, max_tokens=800):
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_message}
    ]
    
    try:
        response = completion(
            model=f"ollama/{MODEL_NAME}",
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens
        )
        return response["choices"][0]["message"]["content"]
    except Exception as e:
        print("Model error:", e)
        return ""

def call_task_parser(text: str) -> dict:
    """
    Convert natural language into structured task JSON.
    Returns dict with signature, description, examples.
    """
    system_prompt = """You are a task parser. Convert natural language requests into structured JSON.

Output format (JSON only, no markdown):
{
  "signature": "def function_name(param: type) -> return_type:",
  "description": "Clear description of what the function should do",
  "examples": "function_name(input) -> output"
}

Example:
Input: "Write a function to check if a number is prime"
Output:
{
  "signature": "def is_prime(n: int) -> bool:",
  "description": "Check if a number is prime",
  "examples": "is_prime(7) -> True, is_prime(4) -> False"
}"""

    fallback_order = [
        f"ollama/{MODEL_NAME}",  # Use selected model first
        "ollama/qwen2.5-coder:1.5b",
        "ollama/phi3.5",
        "ollama/llama3.1",
    ]

    for model in fallback_order:
        try:
            response = completion(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": text}
                ],
                temperature=0.1,
                max_tokens=300
            )
            content = response["choices"][0]["message"]["content"].strip()
            
            # Extract JSON from various formats
            # Remove markdown code blocks
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0]
            elif "```" in content:
                content = content.split("```")[1].split("```")[0]
                if content.startswith("json"):
                    content = content[4:]
            
            # Find JSON object boundaries
            start = content.find("{")
            end = content.rfind("}") + 1
            if start != -1 and end > start:
                content = content[start:end]
            
            # Clean up common issues
            content = content.strip()
            
            parsed = json.loads(content)
            
            # Validate required keys
            if "signature" in parsed or "description" in parsed:
                print(f"✓ Successfully parsed with {model}")
                return parsed
                
        except json.JSONDecodeError as e:
            print(f"Parser attempt with {model} failed: JSON decode error at position {e.pos}")
            # Print problematic content for debugging
            if len(content) < 500:
                print(f"  Content: {content[:200]}...")
            continue
        except Exception as e:
            print(f"Parser attempt with {model} failed: {e}")
            continue

    # Fallback: return instruction format
    print("All parser attempts failed, using fallback format")
    return {"instruction": text}

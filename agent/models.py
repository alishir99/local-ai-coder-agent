from litellm import completion

# Default model (you can change this later to experiment)
MODEL_NAME = "qwen3-coder:30b"


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

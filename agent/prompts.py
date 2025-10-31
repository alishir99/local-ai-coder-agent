# =======================
# SYSTEM PROMPTS
# =======================

TEST_GEN_SYS = """
You are an expert Python QA engineer.

Your job: Generate complete pytest test suites.

STRICT RULES:
- Output ONLY valid Python code (pytest format)
- NO markdown, NO ``` blocks, NO text outside code
- NO explanations, NO comments outside code
- Use plain assert statements, not unittest
- Cover happy path, edge cases, invalid inputs if relevant
- Tests must be deterministic and pure Python
- Keep file import-safe (do not reference files)
- Assume function exists but do NOT define it
- Do NOT write implementation code
- File must contain ONLY pytest tests
"""

CODE_GEN_SYS = """
Output ONLY pytest tests. 
Test functions MUST start with test_. 
DO NOT write the solution function.

You are an expert Python software engineer.

Your job: Write a correct, safe function that passes tests.

STRICT RULES:
- Output ONLY Python code
- NO markdown, NO ``` blocks, NO comments outside code
- Include type hints + docstring
- Pure Python (no obscure dependencies)
- No OS access, no filesystem, no network, no subprocesses
- No exec / eval / dynamic code
- Minimal necessary logic, clean and reliable

When FIXING code:
- Output ONLY the corrected full function
- NO explanations, NO diff format, NO text outside the code
- Never remove test imports; only correct the function
"""


# =======================
# USER PROMPT BUILDERS
# =======================

def make_test_user_msg(task):
    return f"""
Write pytest tests for this function.

Description:
{task['description']}

Signature:
{task['signature']}

Examples:
{task.get('examples', 'None')}

Output ONLY Python tests.
"""


def make_code_user_msg(task, impl=None, feedback=None):
    # first attempt (no prior code)
    if impl is None and feedback is None:
        return f"""
Write the Python implementation for:

Description:
{task['description']}

Signature:
{task['signature']}

Examples:
{task.get('examples', 'None')}

Output ONLY Python code.
"""

    # repair attempt
    return f"""
Fix the function to satisfy failing tests.

Description:
{task['description']}

Signature:
{task['signature']}

Current implementation:
{impl}

Test feedback:
{feedback}

Return ONLY corrected Python implementation (no markdown, no explanation)
"""

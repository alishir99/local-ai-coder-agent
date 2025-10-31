#  AI Code Agent

[![CI/CD](https://github.com/yourusername/ai-code-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/ai-code-agent/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/)

An autonomous AI agent that generates, tests, and validates code with comprehensive security and quality checks. Built with local LLMs (Ollama) for complete privacy and control.

##  Features

> ** Proof of Concept** - This is an early-stage project demonstrating AI-driven code generation. Not production-ready.

- ** Automated Test Generation** - Generates basic test suites from natural language descriptions
- ** Code Implementation** - AI-powered code generation with local LLMs
- ** Test-Driven Development** - Automatic test-fix loops (up to 3 attempts)
- ** Supply Chain Security** - Dependency vulnerability scanning with pip-audit
- ** Code Security Analysis** - Static security analysis with Bandit
- ** Mutation Testing** - Code quality validation with mutmut
- ** Web Interface** - Clean, intuitive Gradio UI with real-time progress tracking
- ** Multi-Model Support** - Switch between different local Ollama models
- ** Sandboxed Execution** - All code runs in isolated Docker containers

##  Pipeline Stages

1. **Test Generation** - AI creates pytest test cases from your description
2. **Code Generation** - AI implements the solution
3. **Testing Loop** - Runs tests, fixes failures automatically (up to 3 attempts)
4. **Dependency Audit** - Scans for vulnerable packages
5. **Security Scan** - Checks for security issues in code
6. **Mutation Testing** - Validates test quality and code coverage

##  Quick Start

### Windows

```batch
install_windows.bat
venv\Scripts\activate
python ui.py
```

### macOS

```bash
chmod +x install_mac.sh
./install_mac.sh
source venv/bin/activate
python ui.py
```

### Linux

```bash
chmod +x install_linux.sh
./install_linux.sh
source venv/bin/activate
python ui.py
```

Then open your browser at `http://127.0.0.1:7860`

##  Prerequisites

The installation scripts will handle most dependencies, but ensure you have:

- **Python 3.10+**
- **Docker or Podman**
- **Ollama** (for local LLMs)

##  Manual Installation

If you prefer manual setup:

### 1. Install Dependencies

```bash
# Install Python packages
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Install Ollama
# Visit: https://ollama.com/download
```

### 2. Pull Recommended Models

```bash
ollama pull qwen2.5-coder:1.5b    # Fast, lightweight
ollama pull phi3.5                # Balanced performance
ollama pull llama3.1              # General purpose
ollama pull codellama:13b         # Code-specialized
```

### 3. Build Docker Sandbox

```bash
docker build -t ai-agent-python .
```

### 4. Run the Application

```bash
# Web UI
python ui.py

# Command Line
python -m agent.agent examples/fizzbuzz.json
```

##  Usage Examples

### Web Interface

1. Enter a task description: `"Write a function to check if a number is prime"`
2. Select your preferred model
3. Click "Run Agent"
4. Watch the pipeline execute in real-time
5. Review generated code, tests, and security reports

### Command Line

Create a task JSON file:

```json
{
  "description": "Write a function that checks if a number is prime",
  "signature": "def is_prime(n: int) -> bool:",
  "examples": "is_prime(7) -> True, is_prime(4) -> False"
}
```

Run the agent:

```bash
python -m agent.agent task.json
```

##  Project Structure

```
ai-code-agent/
├── agent/
│   ├── agent.py           # Main pipeline orchestration
│   ├── models.py          # LLM integration
│   ├── prompts.py         # System prompts
│   └── __init__.py        # Package initialization
├── examples/
│   ├── fizzbuzz.json       # Example task
│   └── roman_to_int.json   # Example task
├── eval/
│   ├── metrics.py          # Evaluation metrics
│   └── run_eval.py         # Benchmark runner
├── Dockerfile              # Sandbox environment
├── ui.py                   # Gradio web interface
├── requirements.txt        # Python dependencies
└── install_*.{bat,sh}      # Installation scripts
```

##  Configuration

### Change Default Model

Edit `agent/models.py`:

```python
MODEL_NAME = "qwen2.5-coder:1.5b"  # Change to your preferred model
```

Or select directly in the web UI.

### Adjust Pipeline Settings

Edit `agent/agent.py`:

```python
MAX_TEST_ATTEMPTS = 3        # Maximum test-fix iterations
DEFAULT_TIMEOUT = 120        # Command timeout in seconds
MUTATION_TIMEOUT = 900       # Mutation testing timeout
```

##  Output Files

After each run, the following files are generated:

- `solution.py` - Generated code implementation
- `test_solution.py` - Generated test suite
- `setup.cfg` - Mutation testing configuration

##  Supported Task Types

- Algorithm implementation (sorting, searching, etc.)
- Data structure operations
- String manipulation
- Mathematical computations
- Input validation
- File processing
- API utilities
- And more!

##  Security & Privacy

- **100% Local** - All code runs on your machine
- **No External APIs** - Uses local Ollama models
- **Sandboxed Execution** - Docker isolation for generated code
- **Supply Chain Scanning** - Automatic dependency vulnerability checks
- **Static Analysis** - Bandit security scanning

##  Testing

Run the evaluation suite:

```bash
python -m eval.run_eval
```

Run mutation tests on existing code:

```bash
python -m agent.agent examples/fizzbuzz.json
```

##  Contributing

Contributions are welcome! Areas for improvement:

- Additional LLM integrations (OpenAI, Anthropic, etc.)
- More sophisticated prompting strategies
- Enhanced mutation testing strategies
- Additional security scanners
- Performance optimizations
- UI enhancements

##  License

MIT License - See LICENSE file for details

##  Acknowledgments

Built with:
- [Ollama](https://ollama.com/) - Local LLM runtime
- [Gradio](https://gradio.app/) - Web UI framework
- [pytest](https://pytest.org/) - Testing framework
- [mutmut](https://github.com/boxed/mutmut) - Mutation testing
- [Bandit](https://bandit.readthedocs.io/) - Security scanner
- [pip-audit](https://github.com/pypa/pip-audit) - Dependency scanner

##  Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the examples/ directory for reference

---

**Note**: This is an experimental AI agent. Always review generated code before using in production. The agent is designed for educational and development purposes.

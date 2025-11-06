# Codebase Genius - Backend

Multi-agent code documentation system built with Jac.

## 🚀 Quick Start

### 1. Setup Environment

```bash
# Create virtual environment
python -m venv venv

# Activate (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# Activate (Linux/Mac)
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Environment

Edit `.env` file and add your API key:

```bash
# For OpenAI
OPENAI_API_KEY=your_key_here

# For Gemini
GEMINI_API_KEY=your_key_here
```

### 4. Run the Server

```bash
jac serve main.jac
```

The server will start at `http://localhost:8000`

### 5. Test the System

In a new terminal:

```bash
python test_analysis.py
```

## 📁 Project Structure

```
BE/
├── main.jac              # Main application with all walkers
├── requirements.txt      # Python dependencies
├── .env                 # Environment variables
├── test_analysis.py     # Test script
├── repos/              # Cloned repositories (auto-created)
└── outputs/            # Generated documentation (auto-created)
```

## 🤖 Agents

1. **CodeGenius (Supervisor)** - Orchestrates the workflow
2. **RepoMapper** - Clones and maps repository structure
3. **CodeAnalyzer** - Analyzes code and builds dependency graph
4. **DocGenie** - Generates markdown documentation

## 🔧 API Usage

### Analyze Repository

```bash
curl -X POST http://localhost:8000/walker/AnalyzeRepository \
  -H "Content-Type: application/json" \
  -d '{"github_url": "https://github.com/username/repo"}'
```

### Response

```json
{
  "success": true,
  "message": "Analysis started",
  "repository": "https://github.com/username/repo"
}
```

## 📊 Output

Generated documentation will be saved to:
```
./outputs/<repo_name>/docs.md
```

## 🐛 Troubleshooting

### Server won't start
- Ensure Jac is installed: `pip install jaclang`
- Check Python version: `python --version` (3.10+ required)

### Clone fails
- Check internet connection
- Verify repository URL is correct and public
- Check .env file has correct API keys

### No documentation generated
- Check console output for errors
- Verify repository contains Python or Jac files
- Check write permissions for outputs/ directory

## 📝 Notes

- Currently optimized for Python and Jac repositories
- Private repositories not supported yet
- Large repositories may take several minutes to process
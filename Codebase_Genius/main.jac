"""
Codebase Genius - Multi-Agent Code Documentation System
Main entry point and orchestrator
"""

include:py os;
include:py json;
include:py dotenv;

# Load environment variables
dotenv.load_dotenv();

# Gemini API setup
glob GEMINI_API_KEY = os.getenv('GEMINI_API_KEY');
glob OPENAI_API_KEY = os.getenv('OPENAI_API_KEY');

# Node definitions for the graph structure
node Repository {
    has url: str;
    has name: str;
    has local_path: str;
    has file_tree: dict = {};
    has readme_summary: str = "";
    has analysis_status: str = "pending";
}

node FileNode {
    has path: str;
    has type: str;
    has language: str = "";
    has analyzed: bool = False;
    has priority: int = 0;
}

node CodeEntity {
    has name: str;
    has type: str;
    has file_path: str;
    has line_number: int;
    has docstring: str = "";
    has dependencies: list = [];
}

# Edge definitions for relationships
edge contains;
edge calls;
edge inherits;
edge imports;

# Global root node
glob root: Repository = Repository(
    url="",
    name="",
    local_path="",
    file_tree={},
    readme_summary=""
);

# Walker: Code Genius Supervisor
walker CodeGenius {
    has github_url: str;
    has output_path: str = "./outputs";
    has status: dict = {};
    
    can init_repository with `root entry {
        print("🚀 Codebase Genius - Starting analysis...");
        print(f"📦 Repository URL: {self.github_url}");
        
        root.url = self.github_url;
        root.name = self.extract_repo_name(self.github_url);
        root.local_path = f"./repos/{root.name}";
        
        spawn here ++> RepoMapper(repo_node=root);
    }
    
    can extract_repo_name(url: str) -> str {
        parts = url.rstrip('/').split('/');
        return parts[-1].replace('.git', '');
    }
    
    can aggregate_results with Repository entry {
        print("📊 Aggregating results...");
        
        if here.analysis_status == "mapped" {
            print("🔍 Starting code analysis...");
            spawn here ++> CodeAnalyzer(repo_node=here);
        } elif here.analysis_status == "analyzed" {
            print("📝 Generating documentation...");
            spawn here ++> DocGenie(
                repo_node=here,
                output_path=self.output_path
            );
        } elif here.analysis_status == "documented" {
            print("✅ Documentation generation complete!");
            self.status = {
                "success": True,
                "output": f"{self.output_path}/{here.name}/docs.md",
                "repository": here.name
            };
        }
    }
}

# Walker: Repository Mapper
walker RepoMapper {
    has repo_node: Repository;
    
    can map_repository with `root entry {
        print("🗺️  RepoMapper: Mapping repository structure...");
        
        cloned = self.clone_repo(
            self.repo_node.url,
            self.repo_node.local_path
        );
        
        if not cloned {
            print("❌ Failed to clone repository");
            return;
        }
        
        file_tree = self.generate_file_tree(self.repo_node.local_path);
        self.repo_node.file_tree = file_tree;
        
        readme_summary = self.summarize_readme(self.repo_node.local_path);
        self.repo_node.readme_summary = readme_summary;
        
        self.create_file_nodes(file_tree, here);
        
        self.repo_node.analysis_status = "mapped";
        print("✅ Repository mapping complete");
        
        spawn here ++> CodeGenius(github_url=self.repo_node.url);
    }
    
    can clone_repo(url: str, local_path: str) -> bool {
        try {
            import:py git;
            
            os.makedirs(os.path.dirname(local_path), exist_ok=True);
            
            if os.path.exists(local_path) {
                import:py shutil;
                shutil.rmtree(local_path);
            }
            
            print(f"📥 Cloning repository to {local_path}...");
            git.Repo.clone_from(url, local_path);
            return True;
        } except Exception as e {
            print(f"Error cloning repository: {e}");
            return False;
        }
    }
    
    can generate_file_tree(root_path: str) -> dict {
        tree = {
            "name": os.path.basename(root_path),
            "type": "directory",
            "children": []
        };
        
        ignored_dirs = {
            '.git', 'node_modules', '__pycache__', '.venv',
            'venv', '.pytest_cache', '.mypy_cache', 'build',
            'dist', '.eggs', '*.egg-info'
        };
        
        try {
            for item in os.listdir(root_path) {
                if item in ignored_dirs or item.startswith('.') {
                    continue;
                }
                
                item_path = os.path.join(root_path, item);
                
                if os.path.isdir(item_path) {
                    subtree = self.generate_file_tree(item_path);
                    tree["children"].append(subtree);
                } else {
                    tree["children"].append({
                        "name": item,
                        "type": "file",
                        "path": item_path
                    });
                }
            }
        } except Exception as e {
            print(f"Error generating file tree: {e}");
        }
        
        return tree;
    }
    
    can summarize_readme(repo_path: str) -> str {
        readme_files = ['README.md', 'README.txt', 'README', 'readme.md'];
        
        for readme in readme_files {
            readme_path = os.path.join(repo_path, readme);
            if os.path.exists(readme_path) {
                try {
                    with open(readme_path, 'r', encoding='utf-8') as f {
                        content = f.read();
                        summary = content[:500] + "..." if len(content) > 500 else content;
                        return summary;
                    }
                } except Exception as e {
                    print(f"Error reading README: {e}");
                }
            }
        }
        
        return "No README found";
    }
    
    can create_file_nodes(tree: dict, parent_node: Repository) {
        if tree["type"] == "file" {
            file_ext = os.path.splitext(tree["name"])[1];
            language = self.detect_language(file_ext);
            priority = self.calculate_priority(tree["name"], language);
            
            file_node = FileNode(
                path=tree.get("path", ""),
                type="file",
                language=language,
                priority=priority
            );
            
            parent_node ++> file_node;
        } elif "children" in tree {
            for child in tree["children"] {
                self.create_file_nodes(child, parent_node);
            }
        }
    }
    
    can detect_language(extension: str) -> str {
        lang_map = {
            '.py': 'python',
            '.jac': 'jac',
            '.js': 'javascript',
            '.ts': 'typescript',
            '.java': 'java',
            '.cpp': 'cpp',
            '.c': 'c',
            '.go': 'go',
            '.rs': 'rust'
        };
        return lang_map.get(extension.lower(), 'unknown');
    }
    
    can calculate_priority(filename: str, language: str) -> int {
        priority = 0;
        
        entry_points = ['main.py', 'app.py', '__init__.py', 'main.jac'];
        if filename in entry_points {
            priority = 10;
        }
        
        if language in ['python', 'jac'] {
            priority += 5;
        }
        
        return priority;
    }
}

# Walker: Code Analyzer
walker CodeAnalyzer {
    has repo_node: Repository;
    
    can analyze_code with Repository entry {
        print("🔍 CodeAnalyzer: Analyzing code structure...");
        
        file_nodes = [-->](`?FileNode);
        sorted_files = sorted(file_nodes, key=lambda x: x.priority, reverse=True);
        
        for file_node in sorted_files {
            if file_node.language in ['python', 'jac'] and not file_node.analyzed {
                self.analyze_file(file_node);
            }
        }
        
        here.analysis_status = "analyzed";
        print("✅ Code analysis complete");
        
        spawn here ++> CodeGenius(github_url=self.repo_node.url);
    }
    
    can analyze_file(file_node: FileNode) {
        try {
            with open(file_node.path, 'r', encoding='utf-8') as f {
                content = f.read();
                
                entities = self.extract_entities(content, file_node.path);
                
                for entity in entities {
                    code_entity = CodeEntity(
                        name=entity['name'],
                        type=entity['type'],
                        file_path=file_node.path,
                        line_number=entity.get('line', 0),
                        docstring=entity.get('docstring', '')
                    );
                    
                    file_node ++> code_entity;
                }
                
                file_node.analyzed = True;
            }
        } except Exception as e {
            print(f"Error analyzing {file_node.path}: {e}");
        }
    }
    
    can extract_entities(content: str, file_path: str) -> list {
        entities = [];
        lines = content.split('\n');
        
        for i, line in enumerate(lines) {
            stripped = line.strip();
            
            if stripped.startswith('class ') {
                class_name = stripped.split('(')[0].split(':')[0].replace('class ', '').strip();
                entities.append({
                    'name': class_name,
                    'type': 'class',
                    'line': i + 1
                });
            }
            
            if stripped.startswith('def ') {
                func_name = stripped.split('(')[0].replace('def ', '').strip();
                entities.append({
                    'name': func_name,
                    'type': 'function',
                    'line': i + 1
                });
            }
        }
        
        return entities;
    }
}

# Walker: Documentation Generator
walker DocGenie {
    has repo_node: Repository;
    has output_path: str;
    
    can generate_docs with Repository entry {
        print("📝 DocGenie: Generating documentation...");
        
        repo_output_dir = f"{self.output_path}/{here.name}";
        os.makedirs(repo_output_dir, exist_ok=True);
        
        doc_content = self.create_documentation(here);
        
        output_file = f"{repo_output_dir}/docs.md";
        with open(output_file, 'w', encoding='utf-8') as f {
            f.write(doc_content);
        }
        
        here.analysis_status = "documented";
        print(f"✅ Documentation saved to {output_file}");
    }
    
    can create_documentation(repo: Repository) -> str {
        doc = f"# {repo.name} - Code Documentation\n\n";
        doc += f"**Repository:** {repo.url}\n\n";
        doc += "---\n\n";
        
        doc += "## 📋 Project Overview\n\n";
        doc += f"{repo.readme_summary}\n\n";
        
        doc += "## 📁 File Structure\n\n";
        doc += "```\n";
        doc += self.format_file_tree(repo.file_tree, 0);
        doc += "```\n\n";
        
        doc += "## 🔍 Code Analysis\n\n";
        
        file_nodes = [-->](`?FileNode);
        
        for file_node in file_nodes {
            if file_node.analyzed {
                doc += f"### {os.path.basename(file_node.path)}\n\n";
                
                entities = file_node [-->](`?CodeEntity);
                
                if entities {
                    doc += "**Code Entities:**\n\n";
                    
                    for entity in entities {
                        doc += f"- **{entity.type.capitalize()}**: `{entity.name}` (line {entity.line_number})\n";
                    }
                    
                    doc += "\n";
                }
            }
        }
        
        doc += "## 📚 API Reference\n\n";
        doc += "### Functions\n\n";
        
        all_entities = [-->](`?CodeEntity);
        functions = [e for e in all_entities if e.type == 'function'];
        
        for func in functions[:20] {
            doc += f"#### `{func.name}`\n\n";
            doc += f"- **File:** {os.path.basename(func.file_path)}\n";
            doc += f"- **Line:** {func.line_number}\n\n";
        }
        
        return doc;
    }
    
    can format_file_tree(tree: dict, indent: int) -> str {
        output = "";
        prefix = "  " * indent;
        
        if tree["type"] == "directory" {
            output += f"{prefix}📁 {tree['name']}/\n";
            if "children" in tree {
                for child in tree["children"] {
                    output += self.format_file_tree(child, indent + 1);
                }
            }
        } else {
            output += f"{prefix}📄 {tree['name']}\n";
        }
        
        return output;
    }
}

# API Walker for HTTP interface
walker AnalyzeRepository {
    has github_url: str;
    has result: dict = {};
    
    can start with `root entry {
        print(f"🌐 API Request: Analyzing {self.github_url}");
        
        if not self.github_url or not self.github_url.startswith('http') {
            self.result = {
                "error": "Invalid GitHub URL",
                "success": False
            };
            return;
        }
        
        genius = spawn here ++> CodeGenius(github_url=self.github_url);
        
        self.result = {
            "success": True,
            "message": "Analysis started",
            "repository": self.github_url
        };
    }
}

# Entry point walker
walker Setup {
    can setup with `root entry {
        print("🎯 Codebase Genius initialized");
        print("Ready to analyze repositories!");
    }
}
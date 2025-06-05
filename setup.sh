if [ -z "$1" ]; then
    echo "Package name required!!"
    exit 1;
fi

PACKAGE="$1"
CLI_PATH="src/${PACKAGE}/cli"

uv init --name "$PACKAGE" --build-backend hatch --author-from git
# uv init --package "$PACKAGE"
uv add "typing-extensions>=4.0.0"

mkdir -p "$CLI_PATH"
sed -i "/project.scripts/a cli = \"$PACKAGE.cli:main\"" pyproject.toml


cat << EOF >> "pyproject.toml"

[tool.hatch.build.targets.wheel]
packages = ["src/${PACKAGE}"]
EOF

cat << EOF >> "${CLI_PATH}/__init__.py"
"""
$PACKAGE CLI Module

Command-line interface for $PACKAGE.
"""

from ._cli import main

__all__ = ['main']
EOF

cat << EOF >> "${CLI_PATH}/_cli.py"
"""
$PACKAGE CLI
"""
import argparse
import json
import sys
from typing import Any

def format_output(data: Any, format_type: str = 'table') -> None:
    """Format and print output data."""
    if format_type == 'json':
        print(json.dumps(data, indent=2, default=str))
    elif format_type == 'table' and isinstance(data, list):
        if not data:
            print("No data found")
            return
        
        # Simple table formatting for lists of dictionaries
        if isinstance(data[0], dict):
            headers = list(data[0].keys())
            print(" | ".join(headers))
            print("-" * (len(" | ".join(headers))))
            for item in data:
                values = [str(item.get(h, '')) for h in headers]
                print(" | ".join(values))
        else:
            for item in data:
                print(item)
    else:
        print(data)


# Workflow commands
def cmd_example(args):
    """Example"""
    response = {}

    if not args.all:
        response = {
            "active": args.active,
            "limit": args.limit,
            "cursor": args.cursor
        }

        format_output(response, args.format)

def create_parser() -> argparse.ArgumentParser:
    """Create the argument parser."""
    parser = argparse.ArgumentParser(
        description='Add description here',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""

Examples:
  cli example
  cli example --active
  cli example --limit 10
  cli example --all
        """
    )
    
    # Global options
    parser.add_argument(
        '--format',
        choices=['table', 'json'],
        default='table',
        help='Output format (default: table)'
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # EXAMPLES BELOW
    # API info command
    example_parser = subparsers.add_parser('example', help='Example operations')
    example_subparsers = example_parser.add_subparsers(dest='example_command')
    
    info_parser = example_subparsers.add_parser('info', help='Get example information')
    info_parser.set_defaults(func=cmd_example)
    
    # Workflows commands
    # workflows_parser = subparsers.add_parser('workflows', help='Workflow operations')
    # workflows_subparsers = workflows_parser.add_subparsers(dest='workflows_command')
    
    # workflows list
    # wf_list_parser = workflows_subparsers.add_parser('list', help='List workflows')
    # wf_list_parser.add_argument('--active', action='store_true', help='Show only active workflows')
    # wf_list_parser.add_argument('--limit', type=int, default=20, help='Limit number of results')
    # wf_list_parser.add_argument('--cursor', help='Pagination cursor')
    # wf_list_parser.add_argument('--all', action='store_true', help='Get all workflows using pagination')
    # wf_list_parser.add_argument('--max-items', type=int, default=100, help='Maximum items when using --all')
    # wf_list_parser.set_defaults(func=cmd_workflows_list)
    
    return parser


def main() -> int:
    """Main CLI entry point."""
    try:
        parser = create_parser()
        args = parser.parse_args()
        
        if not hasattr(args, 'func'):
            parser.print_help()
            return 1
        
        args.func(args)
        return 0
        
    except KeyboardInterrupt:
        sys.stderr.write("\nOperation cancelled by user\n")
        return 1
    except Exception as e:
        print(f"Unexpected error: {e}")
        return 1


def _main() -> None:
    """Legacy main function for compatibility."""
    sys.exit(main())


if __name__ == "__main__":
    sys.exit(main())

EOF

uv run cli

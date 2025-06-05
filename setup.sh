PACKAGE="$1"
CLI_PATH="src/${PACKAGE}/cli"

uv init --package "$PACKAGE"
uv add "typing-extensions>=4.0.0"

mkdir -p "$CLI_PATH"
cat << EOF >> pyproject.toml

[project.scripts]
cli = "$PACKAGE.cli:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
EOF

touch "${CLI_PATH}/__init__.py"
cat << EOF >> "${CLI_PATH}/__main__.py"
"""
$PACKAGE CLI
"""
import argparse
import json
import os
import sys
import time
from typing import Dict, List, Any, Optional

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
            active=args.active,
            limit=args.limit,
            cursor=args.cursor
        }

        format_output(response, args.format)

def create_parser() -> argparse.ArgumentParser:
    """Create the argument parser."""
    parser = argparse.ArgumentParser(
        description='Add description here',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""

Examples:
  cli api info
  cli workflows list --active
  cli executions list --status success --limit 10
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
    api_parser = subparsers.add_parser('api', help='API operations')
    api_subparsers = api_parser.add_subparsers(dest='api_command')
    
    info_parser = api_subparsers.add_parser('info', help='Get API information')
    info_parser.set_defaults(func=cmd_api_info)
    
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

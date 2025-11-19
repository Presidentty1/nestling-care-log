#!/bin/bash

# Setup and add files to Xcode project automatically

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Setting up Xcode project file adder"
echo "======================================"
echo ""

# Check for Ruby
if ! command -v ruby &> /dev/null; then
    echo "❌ ERROR: Ruby is not installed"
    echo "   Install Ruby: brew install ruby"
    exit 1
fi

echo "✅ Ruby found: $(ruby --version)"
echo ""

# Check for xcodeproj gem
if gem list xcodeproj -i &> /dev/null; then
    echo "✅ xcodeproj gem is installed"
else
    echo "📦 Installing xcodeproj gem to user directory..."
    gem install --user-install xcodeproj
    if [ $? -eq 0 ]; then
        echo "✅ xcodeproj gem installed"
        # Add user gem path to Ruby load path
        export GEM_HOME="$HOME/.gem/ruby/$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')"
        export PATH="$GEM_HOME/bin:$PATH"
    else
        echo "❌ ERROR: Failed to install xcodeproj gem"
        echo "   Try running manually: gem install --user-install xcodeproj"
        exit 1
    fi
fi

echo ""
echo "📝 Adding files to Xcode project..."
echo ""

# Run the Ruby script
ruby "$SCRIPT_DIR/add_files_to_xcode.rb"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Success! Files have been added to your Xcode project."
    echo ""
    echo "📝 Next steps:"
    echo "   1. Open Xcode: open $IOS_DIR/Nestling/Nestling.xcodeproj"
    echo "   2. Build: ⌘B"
    echo "   3. Run: ⌘R"
else
    echo ""
    echo "❌ Failed to add files. Check the error messages above."
    exit 1
fi


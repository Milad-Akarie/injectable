#!/bin/bash

# Run tests with coverage for injectable package
cd "$(dirname "$0")"

echo "Running tests with coverage..."

# Run tests with coverage
dart run coverage:test_with_coverage

# Generate HTML coverage report
echo "Generating HTML coverage report..."
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib

# Generate HTML report (requires genhtml from lcov package)
if command -v genhtml &> /dev/null; then
    genhtml coverage/lcov.info -o coverage/html
    echo "Coverage report generated at coverage/html/index.html"
else
    echo "To generate HTML report, install lcov: brew install lcov (macOS) or apt-get install lcov (Linux)"
fi

# Display coverage summary
echo ""
echo "Coverage Summary:"
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib --check-ignore


# Using Tools

## Running Powershell Commands

**Directive**
- Always use the full cmdlet name, not the alias.
- For example, use `Set-Location` instead of `cd`.

**Why**
- This speeds up development since your command is more likely to be auto-approved.

# Working with External Dependencies

## Understanding external dependencies

**Directive**
- Always check the documentation if you're not sure how a library works, or you run into an issue working with a library.

**Why**
- Reading the documentation is fast.
- This is the standard way to do software development.

**Restriction**
- If the documentation doesn't have the answer that you're looking for, you can try decompiling the binary **only** after reading the docs first.
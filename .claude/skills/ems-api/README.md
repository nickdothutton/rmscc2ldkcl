# EMS REST API Skill

This Claude Code Skill provides comprehensive documentation for the Thales Sentinel EMS REST API.

## Directory Structure

```
ems-api/
├── skill.md                    # Main skill definition (Claude reads this first)
├── README.md                   # This file - instructions for populating the skill
├── openapi/                    # OpenAPI/Swagger specifications
│   ├── README.md
│   └── [Add .yaml files here]
├── examples/                   # JSON request/response examples
│   ├── README.md
│   └── [Add .json files here]
└── docs/                       # Additional documentation
    ├── README.md
    └── [Add .md files here]
```

## How to Populate This Skill

### Step 1: Add OpenAPI Specifications

Place OpenAPI/Swagger YAML files in the `openapi/` directory for each endpoint you need to document.

Example: `openapi/entitlements.yaml`

### Step 2: Add Examples

Add real JSON examples in the `examples/` directory:
- Request payloads
- Response payloads
- Error responses

### Step 3: Add Documentation

Create detailed markdown files in the `docs/` directory:
- Authentication details
- Error handling
- Data models
- Workflows

### Step 4: Update skill.md

Update the main `skill.md` file to:
- Reference the new files you've added
- Document any new endpoints
- Update workflow descriptions
- Add usage examples

## How Claude Code Skills Work

When you reference this skill (by invoking it or when Claude automatically detects it's needed), Claude will:

1. Read `skill.md` first to understand the skill's purpose
2. Access referenced files (OpenAPI specs, examples, docs) as needed
3. Use this information to help implement API calls correctly

## Invoking This Skill

Claude Code will automatically use this skill when working with EMS API endpoints. You can also explicitly invoke it:

```
Can you review the EMS API skill and tell me about the entitlements endpoint?
```

## Verification Checklist

Before considering this skill complete, ensure you have:

- [ ] Updated `skill.md` with all endpoint documentation
- [ ] Added OpenAPI specs for each endpoint in `openapi/`
- [ ] Added example requests and responses in `examples/`
- [ ] Created documentation files in `docs/` for:
  - [ ] Authentication
  - [ ] Error handling
  - [ ] Data models
  - [ ] Migration workflows
- [ ] Updated the main `skill.md` references to point to new files
- [ ] Tested that the skill provides accurate information

## Next Steps

1. Start by adding the "Search Entitlements" endpoint documentation (already in use by the script)
2. Add other endpoints as you implement them in the migration tool
3. Keep the skill updated as the API evolves

## Notes

- Keep all paths relative to the skill directory
- Use markdown format for readability
- Include realistic examples with actual data structures
- Document any quirks or gotchas about the API

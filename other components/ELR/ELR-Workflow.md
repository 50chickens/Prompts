

# Candidate Research Automation Plan (Technical Implementation)

This document describes the technical automation pipeline that will replace the manual workflow detailed in humans.md. The automation is implemented via using open-webui as a prompt & tool-calling orchestrator. 

## ELR Workflow Phases

### assignment_scaffold

See the new assignment prompt for details. 

### identify_candidate_constraints

see the data-extraction skill for details.

### Research_companies

use chatgpt to produce a list of companies based on the constraints/context.

### filter_research

manual step for the user to review the ChatGPT responses.

### prepare_linkedin_search

parse the chatgpt responses into a LinkedIn constraints document.

### linkedin_search
    use the constraints document to search LinkedIn

### external_searches

Use additional tooling to perform other searchs for either companies or candidates meeting the candidate constraints.

### candidate_contact

optionally create template for contacting candidates.
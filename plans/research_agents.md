# Research Agents

I want to create the following agents:
- Tech Research Lead - Coordinates other agents and checks their work
- Tech Researcher - Conducts research
- Tech Research Librarian - Organises research documents

## Workflow

- When the user answers a question, the Tech Research Lead will call the Tech Researcher to conduct the research.
- This researcher will conduct the research and create research documents.
- The Tech Research Lead will then check the work.
- The Tech Research Lead will then call the Tech Research Librarian which will ensure that documents are following.

## Tech Research Lead

Responsible for:
- Coordinating the Tech Researcher and Tech Research Librarian
- Checking the work of the Tech Researcher

## Tech Researcher

Responsible for:
- Conducting research to answer questions
- Creating research documentation in markdown format in the `docs/tech-research/` folder

## Tech Research Librarian

Responsible for:
- Organising the research documentation in the `docs/tech-research/` folder
- Ensuring that the documentation is up to date
- Ensuring that CLAUDE.md references appropriate documentation

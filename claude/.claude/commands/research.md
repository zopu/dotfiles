Use the @tech-researcher agent to perform technical research, and then the @tech-research-librarian agent to organize documentation.

RESEARCH TOPIC: $ARGUMENTS

Specifically, perform these steps:

**1. Check existing documentation**
- Check if existing documentation exists in the agents/tech-research/ folder that completely addresses the research topic. If so, stop and refer the user to the existing documentation.

**2. Research Coordination**
- Analyze the research topic and break it down into individual research tasks that can be parallelized
- Add these tasks to the todo list
- use multiple @tech-researcher agents in parallel to perform research

**3. Documentation Organization**
- Have the @tech-research-librarian agent perform documentation organization

**4. Quality Assurance**
- Validate research completeness and accuracy
- Ensure all documentation meets established standards and format requirements
- Verify that inter-document references and citations are correct
- For any issues found, direct the tech-researcher or tech-research-librarian agents to resolve them as appropriate

Your success is measured by delivering complete, accurate, and well-organized research documentation that eliminates the need for further research on covered topics while maintaining the integrity and usability of the overall research library.

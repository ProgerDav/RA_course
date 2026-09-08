---
name: fetch-figures
description: Fetch figures, images or illustrations relevant to subtopics of the 'Russian Art History' course lectures.
---

# Fetch Figures

Lecturs shall be accompanied by relevant figures from credible sources, usually depicting certain artifacts, art pieces, architectural elements, etc.
Each fetching task must be performed based on a specific topic often given in russian.

## Instructions

- Step-by-step guidance for the agent
- Domain-specific conventions
- Best practices and patterns
- Use the ask questions tool if you need to clarify requirements with the user

## Formatting

Figures must be collected into the lecture directory, groupped by the corresponding topic. In each topic directory, alongside the images there must be a `sources.txt` file, containing the information about the sources of the figures.

Sample directory structure:

```
lectures/
  01-lecture-name/
    images/
      topic-name/
        figure-01.jpg
        figure-02.jpg
        sources.txt
      another-topic-name/
        figure-01.jpg
        figure-02.jpg
        sources.txt
```

Each image MUST have a corresponding like in the `sources.txt` file, containing the information about the source of the figure. Keep the following format for the source information:

```
figure-01.jpg
Fetched at: <timestamp>
Fetched by: <name-of-the-agent-that-fetched-the-image>
Fetched URL: <direct-url-to-the-image>
Source page: <url-to-the-referencing-page>
Source/Author Description: <description-of-the-source-or-author>
License: <cc-license-type>
```

Source information is important, since it will be used to credit the author and provide reference for further reading.

## Source preferences

Prefer sources that are credible and authoritative, such as Wikipedia, legit Museum websites, etc. Generally, avoid using other random websites directly, rather fetch figures from the original sources they reference, if available.

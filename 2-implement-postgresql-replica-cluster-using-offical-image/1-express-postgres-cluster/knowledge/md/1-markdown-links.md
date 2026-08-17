# markdown links

1. [link to md file & headings](#how-to-make-a-text-a-link-to-another-md-file-or-some-section-within-md-file-)
2. [can we only link headings](#we-can-only-link-headings--correct-me-if-i-am-wrong-)
3. [github falvored markdown (GFM) slugification](#slugifying-rules-of-md-in-vscode)

## how to make a text a link to another md file or some section within md file ?

```javascript
export const primaryPool = new Pool({
  host: "localhost",
  port: 5432,
  user: "admin",
  password: "password",
  database: "appdb",
});
```

To link text to another file or a specific section in Markdown, use the standard inline link format: [Link Text](Destination).

### 1. Link to Another .md File

To link to a separate file, put the file path inside the parentheses. Use relative paths based on where your current file is located.

- Same folder: [Read more](docs.md)
- Subfolder: [Open guide](resources/guide.md)
- Parent folder: [Go back](../README.md)

### 2. Link to a Section in the Same File

To jump to a specific heading, use a hash symbol (#) followed by the slugified header.

[Link to Section in Another file](#3-link-to-a-section-in-another-file)

### Setup Instructions

How to format the section slug:

- Convert all letters to lowercase.
- Replace all spaces with hyphens (-).
- Remove punctuation marks like commas, periods, or question marks.

### 3. Link to a Section in Another File

Combine the file path and the section slug using a `#` separator.

[View Setup Guide](rules.md#setup-instructions)

### Quick Overview Table

| **Target Destination**   | **Markdown Syntax Example**                            |
| ------------------------ | ------------------------------------------------------ |
| **Another File**         | `[Open File](other-file.md)`                           |
| **Section (Same File)**  | `[Go to Section](#my-heading-title)`                   |
| **Section (Other File)** | `[Go to File Section](other-file.md#my-heading-title)` |

---

## can we only link headings ?

Markdown actually allows you to link to parts of a document that are not headings.

By default, Markdown editors automatically generate linkable anchors only for headings. However, you can link to regular text paragraphs, table rows, or lists by manually adding an HTML anchor.

Here is how you can link to non-heading elements:

### 1. Add an HTML Anchor to the Target Text

Insert an HTML opening tag with an id attribute directly before or inside the target text.

Here is a regular paragraph. `<span id="my-target-paragraph"></span>`This is the exact line you want to link to.

(You can use `<span>`, `<div>`, or `<p>` tags for this).

### 2. Create the Link

Link to that specific ID using a hash symbol (#), just like you would for a heading. [5, 6]

- In the same file: `[Jump to paragraph](#my-target-paragraph)`
- In another file: `[Go to paragraph](file.md#my-target-paragraph)`

---

## slugifying rules of md in vscode

### github falvored markdown (GFM) slugification

Most modern linters (like the markdownlint tool throwing your MD051 error) mimic GitHub's Slugger Algorithm.

- **Downcase:** Converts the entire string to lowercase.Keep: Letters, numbers, hyphens (-), and underscores (_).
- **Strip:** All other punctuation (like ?, !, (, )), but leaves the blank spaces exactly where they were.
- **Convert:** Turns every single remaining space into a hyphen (-).
- **Duplicates:** If two headings slugify to the same exact ID, GitHub appends a number increment (e.g., #my-heading, #my-heading-1).

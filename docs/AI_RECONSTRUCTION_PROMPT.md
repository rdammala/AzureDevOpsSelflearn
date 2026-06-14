# Azure DevOps Learning Platform - Complete Rebuild Specification

**Document Type:** AI-to-AI Prompt / Complete Project Specification  
**Purpose:** Enable another AI tool to rebuild the entire HTML platform from scratch  
**Last Updated:** June 14, 2026  
**Status:** Ready for Implementation  

---

## 🎯 PROJECT OVERVIEW

### Vision
Build a **modern, interactive learning platform** for Azure DevOps professionals covering CI/CD, infrastructure as code, containerization, and interview preparation. The platform should provide:
- Structured learning paths (Beginner → Intermediate → Advanced)
- 50+ interview questions with detailed answers
- 7 comprehensive learning guides
- Interactive features (dark mode, search, progress tracking, code copy)
- Professional UI with Tech Purple + Emerald Green color scheme
- Mobile-responsive design
- Preserved existing content (Mermaid diagrams, code examples, tone)

### Key Goals
✅ Create professional, interactive learning experience  
✅ Improve navigation (side drawer + breadcrumbs)  
✅ Add interactive features (dark mode, search, progress tracking)  
✅ Maintain all existing content and tone  
✅ Responsive design for mobile and desktop  
✅ No backend required (GitHub Pages compatible)  
✅ Smooth animations and modern UI patterns  

### Success Criteria
- Platform loads quickly and works offline
- All pages accessible from any location via navigation
- Dark/light mode toggle persists to localStorage
- Code examples easily copyable with visual feedback
- Progress tracking shows completion percentage
- Search filters content in real-time
- Mobile view stacks vertically, desktop shows optimal layout
- All 50+ interview questions easily searchable by difficulty

---

## 📁 PROJECT STRUCTURE

### Complete File Organization

```
docs/
├── index.html                              # HOME PAGE
├── PLATFORM_REDESIGN_DOCUMENTATION.md      # Design docs (reference only)
│
├── shared/
│   ├── design-system.css                   # DESIGN SYSTEM (600+ lines)
│   ├── app.js                              # JAVASCRIPT APP (200+ lines)
│   └── header.html                         # NAVIGATION COMPONENT
│
└── interview-qa/
    ├── index.html                          # Q&A PLATFORM HUB
    ├── interview-guide-azure-devops.html   # INTERVIEW Q&A
    ├── guides-index.html                   # GUIDES DIRECTORY
    │
    ├── yaml-guide.html                     # YAML PIPELINES GUIDE
    ├── bicep-guide.html                    # INFRASTRUCTURE AS CODE
    ├── powershell-guide.html               # POWERSHELL AUTOMATION
    ├── python-guide.html                   # PYTHON SDK
    ├── csharp-guide.html                   # C# DEVOPS
    ├── docker-guide.html                   # DOCKER BASICS
    ├── kubernetes-guide.html                # KUBERNETES & AKS
    │
    ├── YAML-PIPELINE-GUIDE.md              # Markdown guides (reference)
    ├── BICEP-IaC-GUIDE.md
    ├── POWERSHELL-GUIDE.md
    ├── PYTHON-GUIDE.md
    ├── CSHARP-GUIDE.md
    ├── INTERVIEW-QUESTIONS.md
    └── reproduction-scenarios.ps1/py       # Code examples

Root:
├── README.md                               # Main repo readme
├── agency.toml, bicepconfig.json, etc.     # Config files (unchanged)
└── [All other SupportServices folders]     # Keep unchanged
```

### File Dependencies

```
┌─────────────────────────────────────┐
│ Every HTML Page                     │
├─────────────────────────────────────┤
│ ├─ <link> design-system.css         │
│ ├─ <script> fetch header.html       │
│ │   └─ Auto-injects navigation      │
│ └─ <script> app.js                  │
│    ├─ setupTheme()                  │
│    ├─ setupNavigation()             │
│    ├─ setupSearch()                 │
│    ├─ setupCodeBlocks()             │
│    └─ setupProgressTracking()       │
│                                     │
├─ localStorage (client-side)        │
│  ├─ darkMode (true/false)          │
│  └─ guideProgress (JSON object)    │
└─────────────────────────────────────┘
```

---

## 🎨 DESIGN SYSTEM SPECIFICATIONS

### Color Palette

**Primary Colors:**
```
--primary: #7C3AED           Tech Purple - primary buttons, links
--primary-light: #9F7AEA     Purple light - hover states
--primary-dark: #6D28D9      Purple dark - active/pressed states

--accent: #10B981            Emerald Green - secondary actions, success
--accent-light: #34D399      Green light - hover states
--accent-dark: #059669       Green dark - active/pressed states
```

**Semantic Colors:**
```
--success: #10B981           Green badges (Beginner)
--warning: #F59E0B           Amber badges (Intermediate)
--error: #EF4444             Red badges (Advanced)
--info: #3B82F6              Blue badges (Topics)
```

**Neutral Colors (Dark Mode Default):**
```
--bg-primary: #0F172A        Main background
--bg-secondary: #1E293B      Card background
--bg-tertiary: #334155       Input/border background
--text-light: #F1F5F9        Primary text
--text-muted: #94A3B8        Secondary text

/* Light Mode Override (body.light-mode) */
--bg-primary: #FFFFFF
--bg-secondary: #F8F9FA
--bg-tertiary: #E5E7EB
--text-light: #2D3748
--text-muted: #718096
```

### Spacing System (8px Grid)

```
--spacing-xs: 4px              Tight spacing (button gaps)
--spacing-sm: 8px              Small spacing (padding)
--spacing-md: 12px             Medium spacing (section padding)
--spacing-lg: 16px             Large spacing (main content)
--spacing-xl: 24px             Extra large (major sections)
--spacing-2xl: 32px            Double extra (hero sections)
```

### Typography

```
Font: system-ui, -apple-system, sans-serif
Line Height: 1.6

H1: font-size 2-3rem, font-weight 800    (Page titles)
H2: font-size 1.5rem, font-weight 700    (Section titles)
H3: font-size 1.2rem, font-weight 600    (Subsections)
Body: font-size 1rem, font-weight 400    (Regular text)
Small: font-size 0.875rem, font-weight 400  (Metadata)
Tiny: font-size 0.75rem, font-weight 600    (Badges)

Code: 'Courier New', monospace, font-size 0.85rem
```

### Transitions

```
--transition-fast: 150ms ease-in-out      (Hover effects)
--transition-normal: 300ms ease-in-out    (Standard animations)
--transition-slow: 500ms ease-in-out      (Entrance effects)
```

### Shadows

```
--shadow-sm: 0 1px 2px rgba(0,0,0,0.05)
--shadow-md: 0 4px 6px rgba(0,0,0,0.1)
--shadow-lg: 0 10px 15px rgba(0,0,0,0.1)
--shadow-xl: 0 20px 25px rgba(0,0,0,0.15)
```

### Border Radius

```
--radius-sm: 4px
--radius-md: 6px
--radius-lg: 8px
--radius-xl: 12px
```

### Responsive Breakpoints

```
Mobile: < 768px
- Hamburger menu visible
- Single column layouts
- Stacked cards
- Smaller typography

Desktop: ≥ 768px
- Full horizontal navigation
- Multi-column grids
- Side-by-side layouts
- Larger typography
```

---

## 🧩 UI COMPONENT SPECIFICATIONS

### Component: Header

**Purpose:** Sticky navigation at top of all pages

**Structure:**
```html
<header class="header">
  <div class="header-content">
    <div class="logo">Azure DevOps Learning</div>
    <button class="hamburger-btn">☰</button>  <!-- Mobile only -->
    <button class="theme-toggle">🌙 Dark</button>
  </div>
</header>
```

**Behavior:**
- Sticky position (stays on top while scrolling)
- Logo has gradient text color
- Hamburger button visible only on mobile
- Theme toggle switches dark/light mode
- Persists theme preference to localStorage

---

### Component: Sidebar Navigation

**Purpose:** Collapsible navigation menu accessible from all pages

**Structure:**
```html
<nav class="sidebar">
  <div class="sidebar-header">
    <button class="close-btn">✕</button>
  </div>
  
  <div class="sidebar-section">
    <h3>Main</h3>
    <ul>
      <li><a href="../index.html">🏠 Home</a></li>
      <li><a href="index.html">❓ Q&A Platform</a></li>
      <li><a href="guides-index.html">📚 Learning Guides</a></li>
    </ul>
  </div>
  
  <div class="sidebar-section">
    <h3>Learning Guides</h3>
    <ul>
      <li><a href="yaml-guide.html">📋 YAML Pipelines</a></li>
      <li><a href="bicep-guide.html">🏗️ Infrastructure as Code</a></li>
      <li><a href="powershell-guide.html">⚙️ PowerShell</a></li>
      <li><a href="python-guide.html">🐍 Python</a></li>
      <li><a href="csharp-guide.html">💻 C# DevOps</a></li>
      <li><a href="docker-guide.html">🐳 Docker</a></li>
      <li><a href="kubernetes-guide.html">☸️ Kubernetes</a></li>
    </ul>
  </div>
  
  <div class="sidebar-section">
    <h3>My Progress</h3>
    <div class="progress-bar">
      <div class="progress-fill"></div>
    </div>
    <p class="progress-text">0% Complete</p>
  </div>
</nav>

<div class="sidebar-overlay"></div>  <!-- Click to close -->
```

**Behavior:**
- Hidden by default on desktop, slide-in on mobile
- Overlay backdrop (semi-transparent) closes menu on click
- Smooth slide animation
- Progress bar updates dynamically
- Hamburger button toggles open/close

---

### Component: Badge

**Purpose:** Tag/category indicators with color coding

**Variants:**
```html
<span class="badge badge-success">🟢 Beginner</span>
<span class="badge badge-warning">🟡 Intermediate</span>
<span class="badge badge-error">🔴 Advanced</span>
<span class="badge badge-info">Topic Area</span>
<span class="badge badge-primary">Featured</span>
```

**Styling:**
- Rounded pill shape (border-radius: 20px)
- Padding: 4px 12px
- Font size: 0.75rem
- Font weight: 600
- Color varies by type

---

### Component: Card

**Purpose:** Container for content blocks (guides, questions, topics)

**Features:**
- Border with hover color change
- Shadow that grows on hover
- Smooth transition animations
- Flexbox content layout
- Optional: Top border accent

**Variants:**
- Question Card (with number, difficulty, title, preview)
- Guide Card (with icon, title, description, link)
- Topic Card (with icon, title, description, link)
- Stat Card (with number, label)

---

### Component: Button

**Purpose:** Call-to-action elements throughout site

**Variants:**
```html
<!-- Primary Button -->
<button class="btn btn-primary">Action</button>

<!-- Secondary Button -->
<button class="btn btn-secondary">Alternative</button>

<!-- Link Button -->
<a href="/" class="btn btn-primary">Link Button</a>

<!-- Copy Code Button (special) -->
<button class="copy-btn" onclick="copyCode(this)">📋 Copy</button>
```

**Behaviors:**
- Hover: transform, color change
- Active: darker color
- Disabled: gray with no cursor
- Copy button: shows "✓ Copied!" feedback for 2 seconds

---

### Component: Code Block

**Purpose:** Display syntax-highlighted code with copy functionality

**Structure:**
```html
<div class="code-block">
  <div class="code-header">
    <span>Language/Label</span>
    <button class="copy-btn" onclick="copyCode(this)">📋 Copy</button>
  </div>
  <pre><code>code content here</code></pre>
</div>
```

**Behavior:**
- Copy button initially hidden (opacity: 0)
- Shows on code block hover
- Click copies code to clipboard
- Button shows "✓ Copied!" feedback
- Code area scrolls horizontally on small screens

---

### Component: Search Input

**Purpose:** Live filtering of searchable content

**Behavior:**
- Listens to `keyup` events
- Filters elements with `data-searchable` attribute
- Real-time filtering (no delay)
- Case-insensitive matching
- Show/hide elements based on match

```html
<input type="text" class="search-input" placeholder="Search guides...">
```

**JavaScript Logic:**
```javascript
performSearch(query) {
  const elements = document.querySelectorAll('[data-searchable]')
  elements.forEach(el => {
    const matches = el.textContent.toLowerCase().includes(query.toLowerCase())
    el.style.display = matches ? 'block' : 'none'
  })
}
```

---

### Component: Progress Bar

**Purpose:** Visual indicator of learning progress

**Features:**
- Container with gray background
- Inner fill with gradient (purple → green)
- Updates dynamically based on visited guides
- Shows percentage text next to it

**Data Source:**
```javascript
const visited = Object.keys(
  JSON.parse(localStorage.getItem('guideProgress') || '{}')
).length
const percentage = Math.round((visited / 7) * 100)
```

---

## 📄 PAGE SPECIFICATIONS

### Page 1: HOME (`docs/index.html`)

**Purpose:** Platform gateway and content discovery

**Sections (Top to Bottom):**

#### 1. Hero Section
```
Background: Linear gradient (Purple → Green)
Content:
  - Title: "🚀 Azure DevOps & Cloud Mastery"
  - Subtitle: "Your comprehensive guide to platform engineering..."
  - Radial gradient overlay for depth
```

#### 2. Search Bar
```
Component: Single search input
Function: Live filtering across all content
Placeholder: "Search guides, topics, code examples..."
Styling: Full width, prominent, rounded corners
```

#### 3. Statistics Grid
```
4 Cards in responsive grid:
  - 50+ Interview Questions
  - 7 Learning Guides
  - 8 Topic Areas
  - 50+ Code Examples

Each card:
  - Large number (gradient text)
  - Small label
  - Hover animation (transform, scale)
```

#### 4. Learning Paths Section
```
3 Path Cards (responsive grid):

🟢 BEGINNER TRACK
  - Time: ~5 hours
  - Topics: 3
  - Badges: YAML Basics, Pipelines 101, Docker Intro
  - Link: yaml-guide.html
  - Description: Start here! Learn fundamentals...

🟡 INTERMEDIATE TRACK
  - Time: ~10 hours
  - Topics: 4
  - Badges: Bicep IaC, Advanced YAML, Kubernetes
  - Link: bicep-guide.html
  - Description: Deepen your skills...

🔴 ADVANCED TRACK
  - Time: ~15 hours
  - Topics: Advanced
  - Badges: Production Patterns, Security & RBAC, Enterprise IaC
  - Link: kubernetes-guide.html
  - Description: Master enterprise patterns...
```

#### 5. Topics Grid
```
8 Topic Cards (auto-fit grid):
1. 📋 YAML Pipelines
2. 🏗️ Infrastructure as Code
3. ⚙️ PowerShell Automation
4. 🐍 Python SDK & Automation
5. 💻 C# DevOps & Azure SDK
6. 🐳 Docker & Containerization
7. ☸️ Kubernetes & AKS
8. ❓ Interview Preparation

Each card includes:
  - Icon (emoji)
  - Title
  - 2-3 sentence description
  - Link to guide
```

#### 6. Difficulty Heat Map
```
4 Stats Cards:
  - 🟢 15+ Beginner Questions
  - 🟡 20+ Intermediate Questions
  - 🔴 15+ Advanced Questions
  - 💬 100+ Total Q&A

Styling: Grid layout, gradient text for numbers, hover scale
```

#### 7. Call-to-Action Section
```
Background: Gradient (Green → Green-Dark)
Content:
  - Title: "Ready to Level Up Your DevOps Skills?"
  - Subtitle: "Start with beginner track or dive into advanced topics..."
  - 2 Buttons:
    - "Start Beginner Track" (white background)
    - "Interview Questions" (outline style)
```

#### 8. Footer
```
Logo: "Azure DevOps Learning Platform"
Description: "Master platform engineering, CI/CD, and cloud architecture"
Links:
  - GitHub repo
  - Azure DevOps Docs
  - Microsoft Learn
```

---

### Page 2: Q&A Platform Hub (`docs/interview-qa/index.html`)

**Purpose:** Question discovery and difficulty filtering

**Sections:**

#### 1. Breadcrumb Navigation
```
Home → Q&A Platform
```

#### 2. Hero Section
```
Title: "❓ Interview Q&A Platform"
Subtitle: "Comprehensive collection of hands-on interview questions..."
Background: Gradient (purple)
```

#### 3. Statistics Grid
```
4 Cards:
  - 50+ Interview Questions
  - 3 Difficulty Levels
  - 8 Topic Areas
  - 100% Free & Open
```

#### 4. Filter Controls
```
Buttons:
  - All Questions (default active)
  - 🟢 Beginner (15+)
  - 🟡 Intermediate (20+)
  - 🔴 Advanced (15+)

Behavior: Click to filter questions, update active state
```

#### 5. Questions Grid
```
8 Question Cards in responsive grid:

Each card contains:
  - Number badge (#1, #2, etc.) - circular, purple background
  - Difficulty icon (🟢 🟡 🔴) - top right
  - Title (bold, 1.1rem)
  - Preview text (muted color, 2-3 lines)
  - Topic badges (blue, rounded)
  - Footer with difficulty label + "View Answer →" button

Clicking "View Answer" links to interview guide
```

#### 6. Call-to-Action
```
Title: "📊 Ready to Get Started?"
Subtitle: "View all questions with detailed answers and code examples"
Button: "View Full Interview Guide →" (links to interview-guide)
```

---

### Page 3: Interview Guide (`docs/interview-qa/interview-guide-azure-devops.html`)

**Purpose:** In-depth Q&A with detailed answers and code examples

**Sections:**

#### 1. Breadcrumb Navigation
```
Home → Q&A Platform → Interview Guide
```

#### 2. Page Header
```
Title: "💼 Azure DevOps Interview Preparation Guide"
Subtitle: "Master 50+ hands-on interview questions..."
```

#### 3. Filter Section
```
Title: "Filter by Difficulty"
Buttons: All, 🟢 Beginner, 🟡 Intermediate, 🔴 Advanced
Behavior: Re-render questions based on filter
```

#### 4. Questions Container
```
Dynamic rendering of 8 questions:

Each question item:
  ┌─ Question Header (clickable to expand)
  │  ├─ Number (#1, #2)
  │  ├─ Difficulty Badge (🟢 🟡 🔴)
  │  ├─ Title (clickable area)
  │  └─ Expand Icon (chevron, rotates on expand)
  │
  └─ Question Body (max-height: 0, transitions to max-height on expand)
     ├─ Question Text (bold "Question:")
     ├─ Answer Section (blue border-left)
     │  └─ Detailed explanation
     ├─ Code Example (if applicable)
     │  ├─ Code header with language label
     │  ├─ Copy button
     │  └─ Pre-formatted code
     └─ Pro Tips Box (gradient background, white text)
```

**Questions Data Structure:**
```javascript
const questions = [
  {
    id: 1,
    difficulty: 'beginner',
    title: 'What is Azure DevOps?',
    question: 'Explain the core components...',
    answer: 'Azure DevOps is a platform...',
    codeExample: 'trigger:\n  - main\npool:\n  vmImage: ubuntu-latest',
    tips: 'Remember: DevOps unites people...'
  },
  // ... 7 more questions
]
```

---

### Page 4: Learning Guides Index (`docs/interview-qa/guides-index.html`)

**Purpose:** Guide discovery with learning path recommendations

**Sections:**

#### 1. Breadcrumb Navigation
```
Home → Learning Guides
```

#### 2. Hero Section
```
Title: "📚 Comprehensive Learning Guides"
Subtitle: "Master Azure DevOps, CI/CD, Infrastructure as Code..."
Background: Gradient (purple)
```

#### 3. Beginner Learning Path
```
Section: "🟢 Beginner Path: Start Here!"
Content: Listed recommended sequence
  1. 📋 YAML Pipelines 101 - Learn pipeline basics
  2. 🐳 Docker Essentials - Introduction to containerization
  3. ❓ Interview Prep - Practice beginner questions

All items are links to respective guides
```

#### 4. Intermediate Learning Path
```
Section: "🟡 Intermediate Path: Deepen Your Skills"
Content: Listed recommended sequence
  1. 🏗️ Infrastructure as Code - Bicep templates
  2. ⚙️ PowerShell Automation - Scripting for DevOps
  3. ☸️ Kubernetes Basics - Container orchestration
```

#### 5. Advanced Learning Path
```
Section: "🔴 Advanced Path: Master DevOps"
Content: Listed recommended sequence
  1. 🐍 Python for DevOps - Advanced automation
  2. 💻 C# & Azure SDK - Programmatic cloud management
  3. ❓ Advanced Interview Prep - Master complex scenarios
```

#### 6. All Guides Grid
```
8 Guide Cards in responsive grid:

Card 1: YAML Pipelines (📋)
  - Header: Purple gradient with emoji
  - Title: "YAML Pipelines"
  - Description: "Master Azure DevOps YAML syntax..."
  - Badges: Beginner Friendly, Pipelines
  - Footer: "📖 In-depth guide" + "Read →" button

Card 2: Infrastructure as Code (🏗️)
  - Header: Purple gradient
  - Title: "Infrastructure as Code"
  - Description: "Learn Bicep templates..."
  - Badges: Intermediate, IaC
  - Footer: "📖 In-depth guide" + "Read →" button

[Similar for all 8 guides...]
```

---

## 🔧 JAVASCRIPT FUNCTIONALITY SPECIFICATIONS

### JavaScript Class: AzureDevOpsApp

**Purpose:** Core interactivity engine

**Constructor:** Initialize on DOMContentLoaded

**Methods:**

#### 1. setupTheme()
```javascript
- Reads localStorage.getItem('darkMode')
- If null or 'true': remove 'light-mode' class (dark mode)
- If 'false': add 'light-mode' class (light mode)
- Default: dark mode enabled
```

#### 2. toggleTheme()
```javascript
- Get current state of body.light-mode
- Toggle class
- Save new preference to localStorage.darkMode
- Update button text/icon
```

#### 3. setupNavigation()
```javascript
- Get hamburger button (.hamburger-btn)
- Get sidebar overlay (.sidebar-overlay)
- Add click listener to hamburger: call toggleSidebar()
- Add click listener to overlay: call closeSidebar()
```

#### 4. toggleSidebar()
```javascript
- Get sidebar (.sidebar)
- Toggle 'open' class
- Sidebar slides in from left (CSS handles animation)
```

#### 5. closeSidebar()
```javascript
- Get sidebar (.sidebar)
- Remove 'open' class
- Sidebar slides out (CSS handles animation)
```

#### 6. setupSearch()
```javascript
- Get search input (.search-input)
- Add 'input' event listener
- On every keystroke: call performSearch(this.value)
```

#### 7. performSearch(query)
```javascript
- If query is empty: show all [data-searchable] elements
- Otherwise:
  - Get all [data-searchable] elements
  - For each element:
    - If element.textContent includes query (case-insensitive):
      - Set display: 'block'
    - Else:
      - Set display: 'none'
```

#### 8. setupCodeBlocks()
```javascript
- Get all .copy-btn buttons
- Add click listener to each: call copyCode(this)
```

#### 9. copyCode(button)
```javascript
- Get nearest .code-block ancestor
- Find <code> element inside
- Extract textContent
- Use navigator.clipboard.writeText(code)
- On success:
  - Change button text to "✓ Copied!"
  - Add 'copied' class (changes color to green)
  - After 2 seconds:
    - Revert text to "📋 Copy"
    - Remove 'copied' class
```

#### 10. setupProgressTracking()
```javascript
- Get page ID from document.body.id (or current guide name)
- If ID exists:
  - Call markGuideComplete(guideId)
  - Update progress bar percentage
```

#### 11. markGuideComplete(id)
```javascript
- Get current progress from localStorage.guideProgress
- If not exists: initialize as empty object {}
- Set progress[id] = true
- Save back to localStorage
- Call getProgressPercentage() and update UI
```

#### 12. getProgressPercentage()
```javascript
- Get progress object from localStorage.guideProgress
- Count keys (visited guides)
- Calculate: (count / 7) * 100
- Return percentage
```

**Initialization:**
```javascript
document.addEventListener('DOMContentLoaded', () => {
  window.app = new AzureDevOpsApp()
  window.app.setupTheme()
  window.app.setupNavigation()
  window.app.setupSearch()
  window.app.setupCodeBlocks()
  window.app.setupProgressTracking()
})
```

---

## 📋 CONTENT SPECIFICATIONS

### Interview Questions (8 Examples)

**Question 1: Beginner**
```
ID: 1
Difficulty: beginner
Title: What is Azure DevOps and what are its main components?
Question: Explain the core components of Azure DevOps...
Answer: [Detailed explanation about Boards, Repos, Pipelines, Test Plans, Artifacts]
CodeExample: [Example showing trigger, pool, steps]
Tips: Remember: DevOps unites people, processes, and products...
```

**Question 2: Beginner**
```
ID: 2
Difficulty: beginner
Title: What is a YAML pipeline in Azure DevOps?
Question: Explain YAML pipelines and their advantages...
Answer: [Explanation of YAML-based pipelines]
CodeExample: [YAML pipeline example with trigger and pool]
Tips: YAML pipelines are version-controlled...
```

[Continue with 6 more questions covering different difficulties and topics]

### Learning Guides (7 Guides)

**Guide 1: YAML Pipelines**
- Content: Comprehensive guide with syntax, examples, best practices
- Sections: Introduction, Basics, Structure, Triggers, Stages, Variables, Templates, Best Practices
- Features: Mermaid diagrams, code examples, pro tips

**Guide 2: Infrastructure as Code (Bicep)**
- Content: Guide to Bicep templates and IaC patterns
- Sections: Introduction, Parameters, Variables, Resources, Outputs, Best Practices
- Features: Code examples, architecture diagrams

**Guide 3: PowerShell Automation**
- Content: PowerShell scripting for Azure operations
- Sections: Basics, Azure Modules, Common Tasks, Error Handling, Examples
- Features: Code snippets, use cases

**Guide 4: Python SDK & Automation**
- Content: Python for Azure operations and automation
- Sections: Installation, Authentication, Common Operations, Examples
- Features: Code samples, best practices

**Guide 5: C# DevOps & Azure SDK**
- Content: C# development with Azure SDKs
- Sections: Setup, Client Libraries, Examples, Patterns
- Features: Code examples, design patterns

**Guide 6: Docker & Containerization**
- Content: Docker fundamentals and containerization
- Sections: Introduction, Dockerfile, Images, Containers, Best Practices
- Features: Commands reference, examples

**Guide 7: Kubernetes & AKS**
- Content: Kubernetes and Azure Kubernetes Service
- Sections: Concepts, Deployments, Services, Monitoring, Best Practices
- Features: YAML examples, troubleshooting

---

## ✅ FEATURE CHECKLIST

### Core Features
- [ ] Dark mode toggle (persists to localStorage)
- [ ] Side drawer navigation (hamburger menu on mobile)
- [ ] Breadcrumb navigation on all pages
- [ ] Live search filtering (data-searchable attributes)
- [ ] Code copy buttons with feedback
- [ ] Progress tracking (visited guides)
- [ ] Responsive design (mobile ≤768px, desktop >768px)
- [ ] Smooth animations and transitions

### Pages
- [ ] Home page (index.html)
- [ ] Q&A Platform Hub (interview-qa/index.html)
- [ ] Interview Guide (interview-qa/interview-guide-azure-devops.html)
- [ ] Guides Index (interview-qa/guides-index.html)
- [ ] 7 Learning Guides (yaml, bicep, powershell, python, csharp, docker, kubernetes)

### Design Elements
- [ ] Header component (sticky, responsive)
- [ ] Sidebar navigation (collapsible, overlay)
- [ ] Badge component (5 variants)
- [ ] Card component (hover effects)
- [ ] Button component (multiple states)
- [ ] Code block component (copy button)
- [ ] Search input (live filtering)
- [ ] Progress bar (dynamic)
- [ ] Stats grid (responsive)
- [ ] Difficulty heat map

### Content
- [ ] 50+ interview questions (distributed across difficulties)
- [ ] 3 learning paths (beginner, intermediate, advanced)
- [ ] 8 topic areas
- [ ] Breadcrumb navigation throughout
- [ ] Filter controls for difficulty levels
- [ ] Expandable question cards
- [ ] Code examples with copy buttons
- [ ] Pro tips and best practices

---

## 🎯 TECHNICAL REQUIREMENTS

### Browser Compatibility
- Chrome/Edge (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (iOS + macOS latest 2 versions)
- Mobile browsers (Chrome Mobile, Safari iOS)

### Performance Requirements
- Page load < 2 seconds
- Search filtering responsive (instant)
- Smooth 60fps animations
- localStorage operations synchronous (no lag)

### Accessibility Requirements
- Semantic HTML throughout
- Color contrast ratios ≥ 4.5:1
- Keyboard navigation support
- Alt text for all images/icons
- ARIA labels where appropriate

### Mobile Optimization
- 768px breakpoint for responsive behavior
- Touch-friendly buttons (min 44x44px)
- Readable text without pinch zoom
- Hamburger menu for navigation
- Single column layout

---

## 🔄 INTEGRATION REQUIREMENTS

### Header Component Injection
All pages should automatically inject the header:
```html
<script>
  fetch('../shared/header.html')
    .then(r => r.text())
    .then(html => {
      const div = document.createElement('div')
      div.innerHTML = html
      document.body.insertBefore(div, document.body.firstChild)
      if (window.app) window.app.setupNavigation()
    })
</script>
```

### CSS Linking
```html
<link rel="stylesheet" href="../shared/design-system.css">
```

### JavaScript Initialization
```html
<script src="../shared/app.js"></script>
```

### Data Attributes
- `data-searchable` - Elements that can be searched
- `data-filter="[difficulty]"` - Question filter buttons

---

## 🚀 DEPLOYMENT INSTRUCTIONS

### Build Steps
1. Ensure all HTML files created
2. Ensure design-system.css is 600+ lines with all components
3. Ensure app.js is 200+ lines with all methods
4. Ensure header.html is complete with all navigation
5. Test all links and navigation paths

### Pre-Deployment Checklist
- [ ] Dark mode toggle working and persists
- [ ] Sidebar opens/closes on mobile
- [ ] Code copy buttons visible and functional
- [ ] Search filtering works real-time
- [ ] Progress tracking saves to localStorage
- [ ] All links navigate correctly
- [ ] Responsive design at 768px breakpoint
- [ ] No console errors in browser DevTools
- [ ] All images/icons display correctly
- [ ] Page load time acceptable

### Deployment to GitHub Pages
1. Push to `main` branch
2. GitHub automatically builds from `docs/` folder
3. Site available at `https://rdammala.github.io/AzureDevOpsSelflearn/`

---

## 📊 SUCCESS METRICS

### User Experience
- Navigation intuitive (users don't get lost)
- Dark mode preference persists across sessions
- Search finds content quickly
- Code examples easy to use (copy button visible)
- Progress tracking motivates learning

### Technical
- Platform loads quickly on all browsers
- No JavaScript errors in console
- Responsive at all breakpoints
- localStorage usage < 1MB
- No external dependencies required

### Content
- 50+ interview questions accessible and filterable
- 7 guides organized and discoverable
- 3 learning paths clearly communicated
- Difficulty levels clearly indicated
- All links working (no 404s)

---

## 🔧 MAINTENANCE GUIDELINES

### Adding New Content
- New questions: Add to `questions` array in JavaScript
- New guides: Create HTML file following template pattern
- New topics: Update all navigation and grids

### Updating Design
- Color changes: Edit CSS variables in design-system.css
- Spacing adjustments: Update --spacing-* variables
- Typography: Edit font-size and font-weight values
- All pages auto-update due to centralized design system

### Troubleshooting Common Issues
- **Header not appearing:** Check fetch path for header.html
- **Dark mode not persisting:** Check localStorage is enabled
- **Code copy not working:** Verify Clipboard API and HTTPS context
- **Search not filtering:** Verify data-searchable attributes on elements
- **Mobile menu not opening:** Check hamburger button is visible at 768px

---

## 📚 CONTENT REFERENCES

### Markdown Guides (Source Material)
These should be converted to HTML or referenced:
- YAML-PIPELINE-GUIDE.md
- BICEP-IaC-GUIDE.md
- POWERSHELL-GUIDE.md
- PYTHON-GUIDE.md
- CSHARP-GUIDE.md
- INTERVIEW-QUESTIONS.md

### External Resources (For Enhancement)
- Azure DevOps Documentation: https://learn.microsoft.com/en-us/azure/devops/
- Microsoft Learn: https://learn.microsoft.com/en-us/training/
- GitHub: https://github.com/rdammala/AzureDevOpsSelflearn

---

## 📝 FINAL NOTES FOR AI RECONSTRUCTION

### Critical Success Factors
1. **Design System is Single Source of Truth** - All pages use CSS variables, so color/spacing changes propagate everywhere
2. **Header Component is Reusable** - All pages fetch and auto-inject it, no duplication
3. **JavaScript is Modular** - Single AzureDevOpsApp class handles all interactivity
4. **Content is Preserved** - All existing tone, diagrams, and code examples maintained
5. **No Backend Required** - Pure static HTML/CSS/JS runs on GitHub Pages

### Build Order Recommendation
1. Create `/shared/` folder with design-system.css, app.js, header.html
2. Create home page (index.html) - tests design system
3. Create Q&A hub (interview-qa/index.html)
4. Create Interview guide (interview-qa/interview-guide-azure-devops.html)
5. Create Guides index (interview-qa/guides-index.html)
6. Create/update 7 learning guides (ensure they fetch header.html)

### Testing Sequence
1. Test design system loads on any page
2. Test header injects correctly
3. Test dark mode toggle and persistence
4. Test search filtering
5. Test code copy functionality
6. Test sidebar navigation
7. Test responsive behavior at 768px
8. Test progress tracking
9. Cross-browser testing
10. Mobile device testing

---

**END OF SPECIFICATION**

This document provides everything needed to reconstruct the entire platform from scratch. All technical details, design specifications, content requirements, and implementation guidelines are included for maximum AI reconstruction accuracy.

**Estimated Reconstruction Time:** 4-6 hours for experienced developer / AI tool
**Complexity Level:** Medium (HTML/CSS/JS with design system patterns)
**Dependencies:** None (static site, no backend)
**Deployment:** GitHub Pages (automatic)

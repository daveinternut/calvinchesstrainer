# Understanding Calvin Chess Trainer
### A guide for a new collaborator (who's newer to coding)

Welcome! This document is here to give you a solid mental picture of the app — what it does, what it's built from, and *how each screen actually thinks* — without drowning you in code. It pairs best with the app itself: **play with each trainer for a few minutes first**, then read the matching section here. By the end you should understand the app well enough that when we sit down to change something together, the conversation makes sense.

A note on what this is *not*: it doesn't talk about files, functions, or code internals. It talks about **logic** — the ideas and rules behind what you see. (There are separate, code-level guides in the project for that; this one is for humans.)

Here's the map of this guide:

1. **What we're building** — the idea behind the app
2. **The technology, explained as a team** — Flutter, Lichess, Stockfish, Claude Code, and the rest, and how they cooperate
3. **The features, screen by screen** — what you do and the logic behind it
4. **Inside the Opening Trainer** — the most interesting logic in the app
5. **How we'll work together** — the rhythm of building it
6. **Mini-glossary** — quick definitions of the terms used here

---

## 1. What we're building

**Calvin Chess Trainer is a chess-learning app for kids.** It is *not* a "play full games against the computer" app. It's more like a **gym with focused exercise machines** — each one drills a single sub-skill that strong players take for granted but beginners find hard:

- knowing the board cold (where is "e4"?),
- reading and making moves written in chess notation,
- *seeing* the board — spotting forks, knowing where a knight can leap,
- understanding what the pieces are worth,
- and playing sensible opening moves.

The design philosophy throughout: **take a big, vague skill and break it into tiny, repeatable drills with instant feedback.** Every tap gets an immediate response — a spoken word, a color flash, a sound. Streaks, speed rounds, and personal-best scores turn practice into a game. The app runs on iPhone, iPad, Android, and the web from one shared design.

---

## 2. The technology, explained as a team

Software is built by combining lots of existing tools so you don't reinvent everything. Think of our stack as a **crew, each member with one job**. Here's who's on the team and what they do.

### Flutter & Dart — the stage and the script
**Flutter** is Google's toolkit for building an app *once* and running it on phones, tablets, and the web. **Dart** is the programming language we write in (this is the language you'll be learning). Everything you *see* — buttons, text, the board, the animations — Flutter draws on screen.
> *Analogy:* Flutter is a theater stage that can be set up in any venue; Dart is the script the cast follows.

### chessground — the chessboard itself
The actual board you tap and drag on comes from **chessground**, a ready-made chessboard built by the team at Lichess (below). It draws the squares and pieces, animates moves, handles taps and drags, and shows the little dots, arrows, and highlights. We didn't build a board from scratch — we use theirs and tell it what to show.
> *Analogy:* a high-quality board-and-pieces set that already knows how to be touched, dragged, and lit up.

### dartchess — the rulebook and referee
**dartchess** (also from Lichess) knows the *rules* of chess: which moves are legal, what counts as check or checkmate, how to read and write moves (so "Qb6" means "queen to b6"), and how to capture an entire board position as one short line of text (called a **FEN** — think of it as a position's barcode). Whenever the app needs to ask "is this move legal?" or "what does this position look like?", dartchess answers.
> *Analogy:* the referee holding the rulebook.

### Lichess — our generous open-source friend
**Lichess** is a free, ad-free, open-source chess website. It helps us two ways. First, its engineers built chessground and dartchess and gave them away for anyone to use. Second, Lichess publishes enormous **open datasets** — millions of tactics puzzles and a library of named openings — which we filtered down and packaged inside the app. When you solve a "make this move" puzzle, that position came from a real game on Lichess.

### Stockfish — the grandmaster brain
**Stockfish** is one of the strongest chess engines in the world — far beyond any human player — and it's free and open source. We use it in **one place only: the Opening Trainer**, where it acts as both your opponent and a live analyst. It can look at any position and say, with a number, exactly how good it is, and what the strong moves are. (Part 4 is all about how we use it.)
> *Analogy:* a tireless grandmaster sitting beside the board who can instantly judge any position and point to the best move.

### Riverpod — the app's memory
At any moment the app is tracking a bunch of facts: your current streak, the seconds left on the clock, which square it's asking for, whose turn it is. Programmers call that bundle of "what's true right now" the **state**. **Riverpod** is the system we use to keep that state in one trustworthy place and to **automatically refresh the screen whenever it changes**. You never manually repaint the score — you change the number in memory, and the display follows along.
> *Analogy:* the app's short-term memory, plus a stage manager who, the instant any fact changes, tells exactly the right part of the screen to redraw.

### GoRouter — the map of screens
An app is a set of screens (home, a menu, a game). **GoRouter** moves you between them and gives each screen an *address*, like a web page has a URL. Tapping a card navigates to that screen; the back button returns.
> *Analogy:* the building's hallways and room numbers.

### just_audio & ElevenLabs — the voice
The friendly voice that says "e," "four," "Queen" isn't your phone's robotic text-to-speech. Those clips were generated by **ElevenLabs** (an AI voice service), saved into the app, and are played back by a sound library called **just_audio**. (For a few one-off phrases the app falls back to the phone's built-in speech.) The little "ding" and "thud" for right and wrong are system sounds.
> *Analogy:* a small pre-recorded soundboard the app triggers at the right moments.

### Firebase — Google's behind-the-scenes services
**Firebase** is a collection of cloud services. Right now we use just one: **Analytics**, which anonymously counts things like "how many people started the Speed Round," so we can see what gets used. Two other Firebase pieces — **sign-in accounts** and a **cloud database** for saving progress across devices — are connected and ready, but **not switched on yet**.
> *Analogy:* a quiet clipboard tallying usage, with a filing cabinet and a sign-in desk waiting in the wings.

### Claude Code — how *we* build it
This is the AI assistant you'll be working with (it wrote this guide). **Claude Code** is an *agentic* coding tool from Anthropic: you describe what you want in plain English — "make the speed round 45 seconds," or "the knight should be draggable" — and it reads the project, finds the right places, writes or edits the code, and runs automatic checks to catch mistakes. It's like a fast pair-programmer who has read the entire codebase.

To keep it fast and accurate, we maintain a set of **guide documents** inside the project — essentially a map of how everything is organized and a few rules of the road. Claude Code reads those first, so it doesn't get lost. Much of our work together will be: describe a change in plain language → review what it proposes → run the app and look → adjust.

### How the team cooperates — one tap, start to finish
It's easiest to see how these fit by following a single action. Suppose you're in the **Files** drill and you tap a column:

1. **chessground** notices the tap and reports *which square* you touched.
2. The app's **logic** (held in memory by **Riverpod**) checks your answer, updates your streak, and asks **just_audio** to play the right sound.
3. Riverpod records the new streak; **Flutter** instantly redraws the streak counter on screen.
4. If you're in a Speed Round, a timer (also living in memory) keeps ticking down in the background.

In the Opening Trainer, two more crew members join: **dartchess** confirms your move is legal and updates the position, and **Stockfish** evaluates the new position and chooses its reply. Same pattern, more brains.

---

## 3. The features, screen by screen

The **home screen** is just the hub — a title and four big cards that take you into the four trainers (plus an info button for the About page). Tapping a card navigates to that trainer's menu. Nothing clever here; it's the lobby.

For each trainer below: **what you do**, then **the logic** behind it.

### The Pieces — "Which Side Wins?"
**What you do:** two groups of chess pieces appear side by side; you tap whichever side is worth more.

**The logic:** every piece has a classic point value — pawn 1, knight 3, bishop 3, rook 5, queen 9 (kings have no value here, since they can't be traded). The app builds two groups, quietly adds up each side, and the larger total is the correct answer — and it makes sure the two sides are *never* equal. There are **five difficulty levels**: the easiest is a single piece against a single piece with a big gap (queen vs. pawn — obvious); the hardest is three or four pieces a side with totals that are *close*, so you actually have to add carefully. In **Practice**, the difficulty ramps up as your streak grows and eases back when you slip; the **Speed Round** mixes levels against a 30-second clock.

### Chess Notation
This trainer teaches the "address system" of the board, in a deliberate progression: **Files → Ranks → Squares → Moves.**
- **Files** are the columns, labeled a–h. **Ranks** are the rows, 1–8. A **square** is one cell, named by its column-and-row, like "e4." A **move** in notation looks like "Qb6" (queen to b6).
- For files, ranks, and squares: the app **says a name out loud** (and shows it), and you **tap the matching column, row, or square**. *Explore* mode is pressure-free — tap anything to hear its name. *Practice* tracks a streak. *Speed* adds the 30-second clock. A **Hard Mode** flips the board to Black's point of view so you can't lean on a memorized picture.
- **Moves** is the payoff: you see a real position (from a Lichess game) and a move written in notation, like "Queen b6," and you must **make exactly that move** on the board. This drills *translating notation into action* — it is not about finding the best move. If you play the right move it sticks and you continue; if you play a different (even if reasonable) move, the piece snaps back and a green arrow shows where it should have gone.

### Chess Vision
The theme here is **"seeing" the board** — spotting relationships, not calculating wins. Four drills:

- **Forks & Skewers:** a target piece (and the enemy king) sit on the board; you tap every square where placing *your* piece would win material with a fork or skewer — or tap "None" if no such square exists. *The clever part:* to guarantee the answers are exactly right, the app effectively **tries your piece on all 64 squares**, and for each promising square it **checks every way the opponent could wriggle out** before accepting it as a real win. It's a lot of behind-the-scenes checking, but it means the drill is never wrong.
- **Knight Sight:** tap all the squares a knight attacks from where it stands. Pure pattern practice for the knight's L-shaped leap.
- **Knight Flight:** move a knight to a target square in the **fewest hops**. The app knows the true minimum (it explores outward from the knight like ripples in a pond until it reaches the goal), so it can tell whether you found the shortest route or offer you a retry. The goal square is marked with an amber ring. (This is the drill we recently improved so you can tap a destination, tap-to-select then tap, *or* drag the knight — whatever feels natural.)
- **Pawn Attack:** steer one piece to capture all the black pawns *without ever landing on a square a pawn guards*. The guarded (dangerous) squares glow faintly red. It starts easy (3 pawns) and climbs to 8. Like Knight Flight, you can tap or drag.

### Opening Fundamentals
The deepest screen in the app — covered on its own in **Part 4**.

### Tactics Trainer
Honest status: this is a **planned screen that isn't built yet**. It has a spot reserved but currently just shows a placeholder. (Forks and skewers, which you might expect here, actually live in Chess Vision.)

### About
Credits (Lichess, ElevenLabs, the Flutter community), the app version, a small feedback box that sends us a message, and a tribute to a chess teacher whose ideas inspired the app.

---

## 4. Inside the Opening Trainer (the interesting one)

This screen is where the logic gets genuinely clever, so it's worth slowing down. **The experience first**, then **how it actually thinks**.

**The experience:** you play the opening moves of a game against the computer. A two-colored bar above the board shows who's ahead. As you think, arrows suggest strong moves. After each move you make, it's quietly graded. You can browse a library of famous openings and jump into one, tap any of your pieces to see how good each of its possible moves would be, take moves back, and replay the whole game afterward.

Now, the logic — built up in layers. The wonderful thing is that **almost everything on this screen comes from one idea**: *ask Stockfish to score a position.* Watch how many features are just different costumes on that one idea.

**1. The opponent is Stockfish.** When it's the computer's turn, the app hands the current position to Stockfish and asks for a move. Crucially, we can **turn Stockfish's strength down** so it plays at a kid-friendly level instead of crushing a beginner.

**2. Measuring who's winning: the centipawn.** Stockfish doesn't just say "White's a bit better" — it gives a *number*. The unit is the **centipawn**: one hundredth of a pawn. So +100 means White is ahead by about a pawn's worth of advantage; −300 means Black is up roughly a piece; and if Stockfish sees a forced checkmate, it reports "mate in N moves" instead of a number. **This single number is the backbone of the entire screen.**

**3. The evaluation bar is a confidence curve, not a straight ruler.** You'd think the bar should move twice as far for +2 as for +1. It doesn't — *on purpose*. Going from dead-even (0.0) to +1 is a big deal: it's the difference between a coin flip and a real edge. But going from +8 to +9 barely matters — you were already almost certainly winning. So the app bends the raw centipawn number through an **S-shaped curve** (an idea borrowed from statistics) that turns "material advantage" into something closer to **"chance of winning."** The bar fills toward whoever is more likely to win, and it deliberately **never slams all the way to one end** — there's always a sliver of the other color, because chess always carries some uncertainty. This is a small but genuinely elegant piece of logic, and a great first thing to study together.

**4. Grading your move: compare before and after.** Every move changes the evaluation. The trainer looks at how good your position was *before* your move versus *after* it (from your side's point of view) and asks: did you hold your ground, gain, or give something away? It then sorts the result into the familiar buckets chess sites use — **brilliant, best, good, "book," inaccuracy, mistake, blunder.** A move that barely changes the eval is "best" or "good"; a move that hands the opponent a big swing is a "mistake" or "blunder." Note the important nuance: **"good" doesn't mean you played the single computer-best move** — it means you didn't throw your position away. (The special "book" label is explained next.)

**5. The hints, and why they sharpen the longer you wait.** In practice you'll see arrows pointing at strong moves. Here's the neat trick: a chess engine gets *better the longer it thinks*, but you don't want to stare at a loading spinner. So the app asks Stockfish for a **quick first opinion** (shallow, near-instant) and shows those arrows immediately — then quietly asks again with more thinking time, and again, **refining the suggestions in waves** over a few seconds. The little "thinking" animation is showing you those waves. If you move before it's done, it throws away the unfinished thinking. The arrows are colored by the same grading scale from step 4, and the very best move's arrow is drawn a bit larger. That trade-off — *fast-but-rough* versus *slow-but-strong*, and how to enjoy both — shows up all over software, not just chess.

**6. The opening "book" — knowing what you're playing.** Chess has a vast, named catalog of opening sequences — the Italian Game, the Sicilian Defense, thousands more, each with a code. We bundled that catalog (from Lichess) into the app. As you play, the trainer **matches your sequence of moves against the catalog** and shows the name of the opening you're in — and it knows which of your moves are "book" (established, respected theory) versus your own inventions. The opening **picker** that lets you browse and jump into a named line is reading from this same catalog. So when a move is graded **"book,"** it means "this is a known, sound opening move," which is why it's judged kindly even if it isn't the single top engine choice.

**7. Difficulty is a set of dials on the same engine.** The difficulty levels aren't different opponents — they're **four knobs turned together**: how *strong* Stockfish plays, how *long* it's allowed to think per move, how *strict* it is before counting your move a real mistake, and how many *lives* you get. Easy = weaker, faster, forgiving, three lives. Hard = much stronger, more thinking, strict, one life.
> **A heads-up for us, as collaborators:** today the app opens this screen automatically in an easy, practice-style setup. The **difficulty picker, the "lives" hearts, and the medal rewards are designed and even built in the code — but not yet connected to the screen.** Switching them on would be an excellent early project for us: it's a clear, satisfying way to see how a feature travels from "exists in the code" to "visible to the player."

**8. The per-piece "what if" analysis.** You can tap one of your own pieces, and the trainer will quietly evaluate *each square that piece could move to* and mark them — strong options, dubious ones — using the same grading scale. It's like asking the grandmaster, "what are my choices with this knight?" and getting each one rated. It's the very same "score the position" idea, applied once per candidate move.

**9. Take-backs and replay.** Because the app remembers the **full history** of the game — each position and its evaluation — you can undo a move, or, after the game, step forward and backward through it to review what happened. The history is just a remembered list; moving through it is replaying that list.

**The big lesson:** look back at steps 3, 4, 5, and 8 — the eval bar, the move grades, the hint arrows, and the per-piece analysis. They *look* like four different features, but every one is just a different way of presenting the same core action: **"Stockfish, score this position."** That's a beautiful and very common pattern in software — build one small, solid idea, then reuse it in many shapes. It's worth remembering as you learn.

---

## 5. How we'll work together

You don't need to memorize the code to be a real collaborator. Understanding the **logic** — what each screen is doing and why, which is exactly what this guide covers — is the foundation that makes our working sessions productive.

The rhythm will usually look like this:

1. **Pick a small, concrete change** ("make the goal ring brighter," "let the speed round be 45 seconds," "turn on the opening difficulty picker").
2. **Describe it in plain English to Claude Code.** It finds the right places and proposes the change.
3. **Review and run the app** to see the result — the truth is always on the screen, not in a description.
4. **Adjust** and repeat.

Good first projects, roughly easiest to hardest: tweak a number or a color (small and safe — a great confidence builder); change a sound or a piece of on-screen text; then something with real logic, like switching on the Opening Trainer's difficulty/lives/medals. Each one teaches you a bit more about how the pieces in Part 2 fit together.

As you go, two habits pay off: **play the app often** (it's the fastest way to feel whether a change is right), and when something puzzles you, **ask "which part of the team is responsible?"** — is this a board thing (chessground), a rules thing (dartchess), a memory thing (Riverpod), a brains thing (Stockfish)? That single question will orient you surprisingly often.

---

## 6. Mini-glossary

- **State** — the bundle of facts that are true right now (score, streak, whose turn). Held by Riverpod; when it changes, the screen redraws.
- **Notation** — the written language of chess moves. "e4" is a square; "Qb6" is a move (queen to b6).
- **FEN** — a way to write down a whole board position as one short line of text. The app's way of "saving" a position.
- **Engine** — a program that plays/analyzes chess. Ours is Stockfish.
- **Evaluation (eval)** — the engine's score for a position.
- **Centipawn** — the unit of that score: one hundredth of a pawn. +100 ≈ "up a pawn."
- **Opening book** — a catalog of known, named opening sequences. Used to name what you're playing and to recognize established ("book") moves.
- **Framework** — a big, reusable foundation you build an app on top of. Ours is Flutter.
- **Agentic coding tool** — an AI (Claude Code) that can read a codebase and make changes from plain-English requests.

---

*This is a living document — as we build, we'll keep it honest. If something here doesn't match what you see in the app, that's a bug in the doc, and worth telling me about.*

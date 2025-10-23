<!doctype html>
<html lang="en-GB">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Language Assessment</title>
  <style>
    body { font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial; line-height:1.5; padding:20px; background:#f7f8fb; color:#111; }
    header { margin-bottom:20px; }
    h1 { margin:0 0 6px 0; font-size:1.6rem; }
    p.lead { margin:0 0 8px 0; color:#444; }
    section.quiz { max-width:900px; margin:0 auto; background:white; padding:18px; border-radius:8px; box-shadow:0 6px 18px rgba(20,30,60,0.06); }
    .question { border-bottom:1px solid #eef2f7; padding:14px 0; }
    .question:last-child { border-bottom:0; }
    .q-head { display:flex; justify-content:space-between; align-items:center; gap:10px; }
    .q-number { font-weight:700; color:#0b63c6; }
    .q-text { margin:8px 0 10px 0; }
    .choices { display:flex; flex-direction:column; gap:8px; }
    label.choice { display:flex; align-items:center; gap:10px; padding:8px 10px; border-radius:6px; cursor:pointer; border:1px solid transparent; }
    input[type="radio"] { transform:scale(1.05); }
    label.choice:hover { background:#fbfdff; border-color:#eef6ff; }
    button.submit-btn { margin-top:10px; background:#0b63c6; color:#fff; border:0; padding:8px 12px; border-radius:6px; cursor:pointer; }
    button.submit-btn:disabled { background:#9bbde6; cursor:default; }
    .feedback { margin-top:10px; font-weight:700; }
    .correct { color: #0b8a3e; }
    .incorrect { color:#c62828; }
    .answer-expl { margin-top:6px; color:#333; font-weight:500; }
    footer { margin-top:18px; color:#555; font-size:0.95rem; text-align:center; }
    @media (prefers-reduced-motion:reduce){ * { transition:none !important; } }
  </style>
</head>
<body>
  <header>
    <h1>Language Assessment</h1>
    <p class="lead">A 20-question British English multiple choice test. Submit each question individually to see immediate feedback. The test progresses from elementary to upper-intermediate level.</p>
  </header>

  <section class="quiz" id="quiz"></section>

  <footer>Good luck — answer each question and check your feedback immediately.</footer>

  <script>
    // Questions: progression from elementary to upper-intermediate
    // Each question: text, choices array, index of correct answer (0-based), brief explanation (British English)
    const QUESTIONS = [
      // Elementary level (1-5)
      { q: "Choose the correct form: I ____ a student.", choices: ["am", "is", "are", "be"], correct: 0, expl: "Use 'am' with I." },
      { q: "Choose the correct article: She has ____ orange bag.", choices: ["a", "an", "the", "Ø"], correct: 1, expl: "Use 'an' before a vowel sound." },
      { q: "Choose the correct verb: They ____ football every weekend.", choices: ["play", "plays", "playing", "played"], correct: 0, expl: "Use base form 'play' with they in the present simple." },
      { q: "Choose the correct pronoun: This is my book. That book is ____.", choices: ["mine", "my", "me", "I"], correct: 0, expl: "'Mine' is the possessive pronoun." },
      { q: "Choose the correct preposition: The cat is ____ the table.", choices: ["on", "in", "at", "by"], correct: 0, expl: "'On' indicates position atop something." },

      // Pre-intermediate (6-10)
      { q: "Choose the correct tense: She ____ to Paris last year.", choices: ["went", "goes", "has gone", "going"], correct: 0, expl: "Past simple for a finished action in the past." },
      { q: "Choose the correct comparative: This problem is ____ than the last one.", choices: ["easier", "more easy", "most easy", "easiest"], correct: 0, expl: "Use '-er' for short adjectives." },
      { q: "Choose the correct modal: You ____ wear a helmet when cycling.", choices: ["should", "mustn't", "might", "would"], correct: 0, expl: "'Should' gives advice." },
      { q: "Choose the correct question form: ____ she like coffee?", choices: ["Does", "Do", "Is", "Did"], correct: 0, expl: "Present simple for third person singular uses 'does'." },
      { q: "Choose the correct plural: One child, two ____.", choices: ["children", "childs", "childes", "child"], correct: 0, expl: "Irregular plural: children." },

      // Intermediate (11-15)
      { q: "Choose the correct passive: The letter ____ yesterday.", choices: ["was sent", "sent", "is sending", "had sent"], correct: 0, expl: "Past passive: was + past participle." },
      { q: "Choose the correct conjunction: He stayed at home ____ he was ill.", choices: ["because", "although", "unless", "so"], correct: 0, expl: "'Because' gives reason." },
      { q: "Choose the correct phrasal verb: Please ____ the lights when you leave.", choices: ["turn off", "turn up", "put on", "take in"], correct: 0, expl: "'Turn off' means switch off." },
      { q: "Choose the correct reported speech: She said she ____ finish the work.", choices: ["could", "can", "will", "may"], correct: 0, expl: "In reported speech 'can' often becomes 'could'." },
      { q: "Choose the correct article: He has ____ MBA from London.", choices: ["an", "a", "the", "Ø"], correct: 0, expl: "'MBA' begins with a vowel sound 'em', so 'an' is correct." },

      // Upper-intermediate (16-20)
      { q: "Choose the correct conditional: If I ____ you, I would apologise.", choices: ["were", "was", "am", "be"], correct: 0, expl: "Second conditional uses 'were' after 'if' for hypothetical situations." },
      { q: "Choose the correct verb pattern: I suggested ____ earlier.", choices: ["leaving", "to leave", "leave", "left"], correct: 0, expl: "'Suggest' is followed by a gerund or that-clause." },
      { q: "Choose the correct idiom meaning: 'to hit the nail on the head' means ____.", choices: ["to be exactly right", "to use a tool", "to be careless", "to make a mistake"], correct: 0, expl: "Common idiom meaning to be exactly right." },
      { q: "Choose the correct subtle difference: Which is more formal in British English?", choices: ["I would like to inform you", "Hey, just to tell you", "Gotta let you know", "Thought you should know"], correct: 0, expl: "The first option is clearly formal." },
      { q: "Choose the correct relative clause: The film, ____ I saw last night, was excellent.", choices: ["which", "that", "who", "where"], correct: 0, expl: "Non-defining clause uses 'which' and commas." }
    ];

    // Utility: Fisher-Yates shuffle
    function shuffle(array) {
      for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
      }
      return array;
    }

    // Create a shuffled copy of choices with mapping to original index
    function shuffledChoices(question) {
      const arr = question.choices.map((text, idx) => ({ text, idx }));
      return shuffle(arr);
    }

    // Render quiz
    const quizEl = document.getElementById('quiz');

    // We'll store for each question the shuffled order so we can check correctness later
    const state = [];

    function render() {
      QUESTIONS.forEach((question, qIndex) => {
        const container = document.createElement('article');
        container.className = 'question';
        container.id = `q-${qIndex}`;

        const qHead = document.createElement('div');
        qHead.className = 'q-head';
        const qNum = document.createElement('div');
        qNum.className = 'q-number';
        qNum.textContent = `Question ${qIndex + 1}`;
        const level = document.createElement('div');
        level.style.fontSize = '0.9rem';
        // label level by index
        const lvl = qIndex < 5 ? 'Elementary' : qIndex < 10 ? 'Pre-intermediate' : qIndex < 15 ? 'Intermediate' : 'Upper-intermediate';
        level.textContent = lvl;
        qHead.appendChild(qNum);
        qHead.appendChild(level);

        const qText = document.createElement('div');
        qText.className = 'q-text';
        qText.textContent = question.q;

        // Prepare shuffled choices
        const shuffled = shuffledChoices(question);
        state[qIndex] = { shuffled }; // store mapping

        const choicesDiv = document.createElement('div');
        choicesDiv.className = 'choices';
        shuffled.forEach((choiceObj, cIndex) => {
          const id = `q${qIndex}_c${cIndex}`;
          const label = document.createElement('label');
          label.className = 'choice';
          label.setAttribute('for', id);

          const radio = document.createElement('input');
          radio.type = 'radio';
          radio.name = `q${qIndex}`;
          radio.id = id;
          radio.value = choiceObj.idx; // original index of this choice
          label.appendChild(radio);

          const span = document.createElement('span');
          span.textContent = choiceObj.text;
          label.appendChild(span);

          choicesDiv.appendChild(label);
        });

        const submitBtn = document.createElement('button');
        submitBtn.className = 'submit-btn';
        submitBtn.textContent = 'Submit';
        submitBtn.addEventListener('click', () => handleSubmit(qIndex, question, submitBtn));

        const feedback = document.createElement('div');
        feedback.className = 'feedback';
        feedback.id = `feedback-${qIndex}`;

        container.appendChild(qHead);
        container.appendChild(qText);
        container.appendChild(choicesDiv);
        container.appendChild(submitBtn);
        container.appendChild(feedback);

        quizEl.appendChild(container);
      });
    }

    function handleSubmit(qIndex, question, btn) {
      const selected = document.querySelector(`input[name="q${qIndex}"]:checked`);
      const feedbackEl = document.getElementById(`feedback-${qIndex}`);

      if (!selected) {
        feedbackEl.textContent = "Please choose an answer.";
        feedbackEl.className = 'feedback incorrect';
        return;
      }

      const chosenOriginalIndex = parseInt(selected.value, 10);
      const correctOriginalIndex = question.correct;

      // Disable further changes for this question after submission
      const radios = document.querySelectorAll(`input[name="q${qIndex}"]`);
      radios.forEach(r => r.disabled = true);
      btn.disabled = true;

      if (chosenOriginalIndex === correctOriginalIndex) {
        feedbackEl.textContent = "Correct";
        feedbackEl.className = 'feedback correct';
      } else {
        feedbackEl.textContent = "Incorrect";
        feedbackEl.className = 'feedback incorrect';
        // Show correct answer line
        const correctText = question.choices[correctOriginalIndex];
        const expl = document.createElement('div');
        expl.className = 'answer-expl';
        expl.textContent = `Correct answer: ${correctText}. ${question.expl}`;
        feedbackEl.parentNode.appendChild(expl);
      }

      // If correct, still show short explanation
      if (chosenOriginalIndex === correctOriginalIndex) {
        const expl = document.createElement('div');
        expl.className = 'answer-expl';
        expl.textContent = question.expl;
        feedbackEl.parentNode.appendChild(expl);
      }
    }

    // Initial render
    render();
  </script>
</body>
</html>

function submitQuiz() {
  const answer = document.querySelector('input[name="q1"]:checked');
  let resultText = "";

  if (!answer) {
    resultText = "Please select an answer.";
  } else if (answer.value === "b") {
    resultText = "✅ Correct! HTML stands for HyperText Markup Language.";
  } else {
    resultText = "❌ Incorrect. Try again!";
  }

  document.getElementById("result").innerText = resultText;
}
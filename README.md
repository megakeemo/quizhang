# QuizHang

QuizHang is a hangman quiz game with time constraints built using the Corona SDK cross platform framework.

The game consists of two different modes: Endurance and Time Trial

1. Endurance
  -	Questions will be multiple choice based.
  -	System will fetch from the database a random question (with its respective category) and 4 possible choices, only 1 of which is correct.
  -	Upon selecting a choice, the system will determine whether or not the choice was correct then move on to another random question. Certain questions will be randomly selected to be a special question.
  -	The start time at the beginning of each new game is 1 minute. Game ends when time runs out, or when the user resets or quits.
  -	Correct answers increase score by 2pts and time by 5 seconds.
  -	Incorrect answers will deduct time left available by 5 seconds.
  -	Non answers (skips) will deduct time left available by 1 second.
  -	Incorrect answers add 0pts.
  -	Score multiplier of x2 when 5 consecutive questions are answered correctly.
  -	Score multiplier of x3 when 15 consecutive questions are answered correctly.
  -	Score subtraction of 15pts and time deduction of -15 seconds when 5 questions are answered incorrectly.

-	Special questions:
    -	Correctly answered, time increases for 15 seconds and point increase of 250pts.
    -	Incorrectly answered time decreases by 25 seconds.
    -	Skipping Special Questions will not incur a penalty.

  -	Tally total questions given, and the amounts that were entered correctly and incorrectly and display the result to the user in a tabular format (show on Game Over state).
  -	Display final score to the user and save score to disk for later viewing (show on High Scores state). 
  -	Share scores to social media (Facebook, Twitter, and Instagram).

2. Time Trial
  -	There will be no time increases or deductions in this mode and the aim is to have the user answer as many questions as they can within the timeframe.
  -	Questions will be multiple choice based.
  -	System will fetch from the database a random question (with its respective category) and 4 possible choices, only 1 of which is correct.
  -	Upon selecting a choice, the system will determine whether or not the choice was correct then move on to another random question.
  -	The start time at the beginning of each new game is 2 minutes. 

  -	Correct answers increase score by 2pts.
  -	Incorrect answers add 0 points.
  -	Score multiplier of x2 when 5 consecutive questions are answered correctly.
  -	Score multiplier of x3 when 10 consecutive questions are answered correctly.
  -	Score divisor of 2pts and time deduction of -15 seconds when 5 questions are answered incorrectly.

-	Special Questions:
  -	Correctly answered, time increases for 15 seconds and time counter slows down 0.5. Point increase of 500pts.
  -	Incorrectly answered and time decreases by 10 seconds and time counter speeds increases by 1.5.
  -	Skipping Special Questions will not incur a penalty.

  -	Tally total questions given, and the amounts that were entered correctly and incorrectly and display the result to the user in a tabular format (show on Game Over state).
  -	Display final score to the user and save score to disk for later viewing (show on High Scores state). 
  -	Share scores to social media (Facebook, Twitter, Instagram).


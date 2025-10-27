"""A Riddle Master Game"""

import random;
import from byllm.llm { Model }

# glob llm = Model(model_name="gpt-4o",verbose=False);
glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);

"""Generate a creative riddle with answer. Format: 'Riddle: [riddle text] Answer: [answer]'"""
def generate_riddle() -> str by llm();

"""Provide a helpful hint if the answer is incorrect, without revealing the correct answer"""
def give_hint(user_answer: str, correct_answer: str, attempts_left: int) -> str by llm();

"""Check if user's answer is correct (considering synonyms). Return 'correct' or 'incorrect'"""
def check_answer(user_answer: str, correct_answer: str) -> str by llm();

walker RiddleGame {
    has user_answer: str;
    has attempts: int = 5;

    can start with `root entry;
    can process_answer with turn entry;
}

node turn {
    has riddle_text: str;
    has correct_answer: str;
    has attempts_remaining: int;
}

# Will run when in CLI mode (not in cloud)
with entry:__main__ {
    print("🎭 Welcome to Riddle Master! 🎭");
    print("Below is the Riddle, you have 5 attempts to solve the riddle.\n");
    
    root spawn RiddleGame(user_answer="", attempts=5);
}

impl RiddleGame.start {
    if not [root --> (`?turn)] {
        # Generate riddle
        riddle_data = generate_riddle();
        
        # Parse riddle and answer
        parts = riddle_data.split("Answer:");
        if len(parts) >= 2 {
            riddle = parts[0].replace("Riddle:", "").strip();
            answer = parts[1].strip();
        } else {
            riddle = "What has keys but no locks, space but no room, and you can enter but can't go inside?";
            answer = "keyboard";
        }
        
        print("\n" + "="*50);
        print(riddle);
        print("="*50);
        print(f"No. of attempts remaining: {self.attempts}");
        
        # Ask for answer AFTER displaying the riddle
        answer1 = input("\nEnter your answer: ");
        self.user_answer = answer1;
        
        next = root ++> turn(riddle_text=riddle, correct_answer=answer, attempts_remaining=self.attempts);
    } else {
        next = [root --> (`?turn)];
    }
    visit next;
}

impl RiddleGame.process_answer {
    if [-->] {
        visit [-->];
    } else {
        result = check_answer(self.user_answer, here.correct_answer);
        
        if "correct" in result.lower() and "incorrect" not in result.lower() {
            print("\n🎉 Congratulations! You guessed correctly! 🎉");
            print(f"The answer was: {here.correct_answer}");
            disengage;
        } else {
            here.attempts_remaining -= 1;
            
            if here.attempts_remaining > 0 {
                print(f"\n❌ Not quite right!");
                print(give_hint(self.user_answer, here.correct_answer, here.attempts_remaining));
                print(f"No. of attempts remaining: {here.attempts_remaining}");
                
                here ++> turn(riddle_text=here.riddle_text, correct_answer=here.correct_answer, attempts_remaining=here.attempts_remaining);
                
                # Get next answer
                next_answer = input("\nEnter your answer: ");
                root spawn RiddleGame(user_answer=next_answer, attempts=here.attempts_remaining);
            } else {
                print(f"\n😔 Sorry! You've run out of attempts.");
                print(f"The correct answer was: {here.correct_answer}");
                disengage;
            }
        }
    }
}
import os
import google.generativeai as genai

# 1️⃣ Set your Gemini API key
os.environ["GOOGLE_API_KEY"] = "AIzaSyAdDbspUCcJnvXAlj5BG-WlB3e_bnNrQOI"  # 🔑 Replace with your key
genai.configure(api_key=os.environ["GOOGLE_API_KEY"])

# 2️⃣ Load Gemini model
model = genai.GenerativeModel("gemini-2.0-flash")

# 3️⃣ Generate a riddle and answer from Gemini
riddle_prompt = """
Create a fun riddle for a general audience.
Return as JSON with fields: riddle, answer
"""
riddle_resp = model.generate_content(riddle_prompt)

import json, re

# Extract JSON safely from Gemini response
json_match = re.search(r"\{.*\}", riddle_resp.text, re.S)
if json_match:
    riddle_pack = json.loads(json_match.group())
else:
    raise ValueError("Gemini did not return proper JSON.")

riddle = riddle_pack["riddle"]
answer = riddle_pack["answer"].lower()

print("\n🤔 Here's your riddle:")
print(riddle)

# 4️⃣ Gameplay Loop with 5 attempts
MAX_ATTEMPTS = 5
for attempt in range(1, MAX_ATTEMPTS + 1):
    guess = input(f"\nAttempt {attempt}/{MAX_ATTEMPTS} - Your guess: ").strip().lower()

    if guess == answer:
        print(f"🎉 Correct! The answer is: {answer}")
        break
    else:
        if attempt < MAX_ATTEMPTS:
            # Ask Gemini for a creative hint
            hint_prompt = f"""
            The riddle is: {riddle}
            The correct answer is: {answer}
            The player guessed: {guess}
            Give a **short** fun hint to guide them closer without revealing the answer.
            """
            hint_resp = model.generate_content(hint_prompt)
            print("💡 Hint:", hint_resp.text.strip())
        else:
            print(f"❌ Out of attempts! The correct answer was: {answer}")

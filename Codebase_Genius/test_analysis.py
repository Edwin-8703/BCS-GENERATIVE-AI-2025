"""
Test script for Codebase Genius
"""
import requests
import json
import time

# Configuration
JAC_SERVER_URL = "http://localhost:8000"
TEST_REPO = "https://github.com/jaseci-labs/jaclang-tutorials"

def test_analyze_repository():
    """Test repository analysis"""
    print("🧪 Testing Codebase Genius...")
    print(f"📦 Test Repository: {TEST_REPO}")
    
    # Prepare request
    payload = {
        "github_url": TEST_REPO
    }
    
    try:
        # Send analysis request
        print("\n📡 Sending analysis request...")
        response = requests.post(
            f"{JAC_SERVER_URL}/walker/AnalyzeRepository",
            json=payload
        )
        
        if response.status_code == 200:
            result = response.json()
            print("\n✅ Response received:")
            print(json.dumps(result, indent=2))
            
            print("\n⏳ Waiting for analysis to complete...")
            time.sleep(5)
            
            print("\n✅ Test completed!")
            print("📂 Check ./outputs directory for generated documentation")
        else:
            print(f"\n❌ Error: {response.status_code}")
            print(response.text)
    
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("\n💡 Make sure the Jac server is running:")
        print("   jac serve main.jac")

if __name__ == "__main__":
    test_analyze_repository()
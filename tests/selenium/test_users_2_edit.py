import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select

def test_edit_user(driver, base_url):
    """Test Case: Edit an existing user."""
    driver.get(f"{base_url}/users")
    
    wait = WebDriverWait(driver, 10)
    
    # 1. Search for the user
    time.sleep(1)
    search_input = wait.until(EC.presence_of_element_located((By.XPATH, "//div[@class='db-search-bar']/input")))
    search_input.clear()
    time.sleep(0.5)
    search_input.send_keys("Selenium Test User")
    time.sleep(1) # Wait for search to filter
    
    # 2. Click "Modify"
    edit_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//tr[.//div[contains(@class, 'user-name-text') and text()='Selenium Test User']]//button[contains(text(), 'Modify')]")))
    time.sleep(1)
    edit_btn.click()
    
    # 3. Update Branch and User Type
    time.sleep(1)
    dept_input = wait.until(EC.presence_of_element_located((By.NAME, "department")))
    dept_input.click()
    dept_input.send_keys(Keys.CONTROL + "a")
    dept_input.send_keys(Keys.BACKSPACE)
    dept_input.send_keys("Information Technology")
    
    time.sleep(0.5)
    role_select = Select(driver.find_element(By.NAME, "role"))
    role_select.select_by_visible_text("Admin")
    
    # 4. Save the changes
    time.sleep(1)
    submit_btn = driver.find_element(By.XPATH, "//button[contains(@class, 'user-form-save-btn')]")
    submit_btn.click()
    
    # 5. Verify the update (search for it again and check)
    time.sleep(2)
    search_input = wait.until(EC.presence_of_element_located((By.XPATH, "//div[@class='db-search-bar']/input")))
    search_input.clear()
    search_input.send_keys("Selenium Test User")
    time.sleep(1)
    
    # Verify the branch text
    wait.until(EC.presence_of_element_located((By.XPATH, f"//span[contains(@class, 'user-branch-text') and text()='Information Technology']")))
    
    print("User edited successfully.")
    time.sleep(2)

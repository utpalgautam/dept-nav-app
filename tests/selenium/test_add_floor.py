import time
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def test_add_floor(driver, base_url):
    """
    Test adding a floor to "Automated Selenium Building".
    """
    driver.get(f"{base_url}/buildings")

    # 1. Search for the building
    time.sleep(3) # Wait to see the full list
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, ".db-search-bar input"))
    )
    search_bar = driver.find_element(By.CSS_SELECTOR, ".db-search-bar input")
    search_bar.send_keys("Automated Selenium Building")
    time.sleep(4) 
    print("Searching for building to add floor...")

    # 2. Click View to open BuildingDetails
    cards = driver.find_elements(By.CLASS_NAME, "building-card")
    found = False
    for card in cards:
        if "Automated Selenium Building" in card.find_element(By.CLASS_NAME, "building-card-name").text:
            view_btn = card.find_element(By.CLASS_NAME, "building-btn-view")
            view_btn.click()
            time.sleep(2)
            found = True
            break
    
    assert found, "The building to add a floor to was not found!"

    # 3. Fill Add Floor Form
    # Tab 'Add Floor Map' is active by default
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CLASS_NAME, "bd-form"))
    )
    
    floor_num_input = driver.find_element(By.CSS_SELECTOR, "input[type='number'][placeholder='e.g. 1']")
    floor_num_input.send_keys("1")
    time.sleep(1)
    
    floor_name_input = driver.find_element(By.CSS_SELECTOR, "input[type='text'][placeholder='e.g. Ground Floor']")
    floor_name_input.send_keys("Testing Floor 1")
    time.sleep(1)
    
    # Description input has placeholder 'e.g. 1' (as seen in BuildingDetails.jsx line 322 - possibly a typo in code but I must match it)
    desc_input = driver.find_element(By.CSS_SELECTOR, "input[type='text'][placeholder='e.g. 1']")
    desc_input.send_keys("Initial floor for testing")
    time.sleep(1)
    
    print("Filled Add Floor details...")

    # 4. Submit
    submit_btn = driver.find_element(By.CLASS_NAME, "bd-form__submit")
    submit_btn.click()
    
    # Wait for success message
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CLASS_NAME, "bd-form__success"))
    )
    time.sleep(2)
    print("Floor added successfully!")

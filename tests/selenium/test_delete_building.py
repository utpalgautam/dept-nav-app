import time
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def test_delete_building(driver, base_url):
    """
    Test searching for and deleting a specific building.
    """
    driver.get(f"{base_url}/buildings")

    # 1. Search for the building
    time.sleep(3) # Wait to see the full list before searching
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, ".db-search-bar input"))
    )
    search_bar = driver.find_element(By.CSS_SELECTOR, ".db-search-bar input")
    search_bar.send_keys("Automated Selenium Building - Edited")
    time.sleep(4) # Increased delay to see the filtered list
    print("Searching for building...")

    # 2. Find and Delete the building
    cards = driver.find_elements(By.CLASS_NAME, "building-card")
    found = False
    for card in cards:
        if "Automated Selenium Building - Edited" in card.find_element(By.CLASS_NAME, "building-card-name").text:
            remove_btn = card.find_element(By.CLASS_NAME, "building-btn-remove")
            remove_btn.click()
            time.sleep(2) # Increased delay before confirmation
            print("Clicked Remove button...")
            found = True
            break
    
    assert found, "The building to delete was not found!"

    # 3. Handle confirmation dialog
    alert = driver.switch_to.alert
    time.sleep(2) # See the alert
    alert.accept()
    time.sleep(2) # See the result of deletion
    print("Accepted deletion alert...")

    # 4. Verify deletion
    time.sleep(4) # Significantly increased delay
    print("Verifying deletion...")
    remaining_names = [el.text for el in driver.find_elements(By.CLASS_NAME, "building-card-name")]
    assert "Automated Selenium Building" not in remaining_names

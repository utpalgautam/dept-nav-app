import time
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def test_edit_building(driver, base_url):
    """
    Test searching for "Automated Selenium Building" and renaming it.
    """
    driver.get(f"{base_url}/buildings")

    # 1. Search for the building
    time.sleep(3) # Wait to see the full list before searching
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, ".db-search-bar input"))
    )
    search_bar = driver.find_element(By.CSS_SELECTOR, ".db-search-bar input")
    search_bar.send_keys("Automated Selenium Building")
    time.sleep(4) # Increased delay to see the filtered list
    print("Searching for building to edit...")

    # 2. Find and click View/Edit
    cards = driver.find_elements(By.CLASS_NAME, "building-card")
    found = False
    for card in cards:
        if "Automated Selenium Building" in card.find_element(By.CLASS_NAME, "building-card-name").text:
            view_btn = card.find_element(By.CLASS_NAME, "building-btn-view")
            view_btn.click()
            time.sleep(2)
            found = True
            break
    
    assert found, "The building to edit was not found!"

    # 3. Click Edit in Details View
    # Note: BuildingDetails component was used in BuildingManagement when viewState is 'details'
    # From BuildingManagement.jsx: <BuildingDetails ... onEdit={() => handleEditBuilding(selectedBuilding)} />
    # I need to find the edit button in BuildingDetails.jsx
    # I'll check BuildingDetails.jsx content first to be sure of the button class/text
    # But I can also look for a button that says "Edit" or has a pencil icon.
    edit_action_btn = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, "//button[contains(., 'Edit')]"))
    )
    edit_action_btn.click()
    time.sleep(2)
    print("Clicked Edit button in details view...")

    # 4. Modify the Name
    name_input = WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.NAME, "name"))
    )
    name_input.clear()
    name_input.send_keys("Automated Selenium Building - Edited")
    time.sleep(2)
    print("Renamed building...")

    # 5. Save Changes
    driver.find_element(By.CLASS_NAME, "bf-save-main-btn").click()
    time.sleep(4)
    print("Saving edited building...")

    # 6. Verify Edit in List
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((By.CLASS_NAME, "building-card-name"))
    )
    building_names = [el.text for el in driver.find_elements(By.CLASS_NAME, "building-card-name")]
    assert "Automated Selenium Building - Edited" in building_names

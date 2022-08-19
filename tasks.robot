*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             OperatingSystem
Library             String
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    #${source}=    Ask for Order Source
    ${source}=    Get Secret    Cert_II
    ${Orders}=    Get orders    ${source}[Source]
    Loop orders    ${Orders}
    ZIP Folder
    [Teardown]    Close Browser


*** Keywords ***
Ask for Order Source
    Add text input    Link    Order Source    URL of CSV    1
    ${source}=    Run Dialog
    RETURN    ${source}[Link]

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${url}
    Download    ${url}    target_file=${OUTPUT_DIR}${/}Orders.csv    overwrite=${TRUE}
    ${table}=    Read table from CSV    ${OUTPUT_DIR}${/}Orders.csv
    Remove File    ${OUTPUT_DIR}${/}Orders.csv
    RETURN    ${table}

Loop orders
    [Arguments]    ${Orders}
    FOR    ${Order}    IN    @{Orders}
        Handle Pop-up
        Select From List By Value    id=head    ${Order}[Head]
        Select Radio Button    body    ${order}[Body]
        Input Text    xpath://input[@class="form-control"]    ${order}[Legs]
        Input Text    address    ${order}[Address]
        Click Button    id=preview
        Wait Until Keyword Succeeds    10x    0.5 sec    Click Order Button
        Save Order As PDF
        Click Button    id=order-another
        Log    ${Order}
    END

Handle Pop-up
    Click Button    OK

Click Order Button
    Click Button    id=order
    Wait Until Page Does Not Contain Element    id:order

Save Order As PDF
    ${order}=    Get Element Attribute    class=badge    outerHTML
    ${length}=    Get Length    ${order}
    ${endOfSubstring}=    Set Variable    ${${length}-${4}}
    ${order}=    Get Substring    ${order}    31    ${endOfSubstring}
    Screenshot    id=robot-preview-image    ${OUTPUT_DIR}${/}robots${/}robot.png
    ${receipt_html}=    Get Element Attribute    id=receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}robots${/}${order}.pdf
    ${picture_list}=    Create List    ${OUTPUT_DIR}${/}robots${/}robot.png
    Add Files To Pdf
    ...    files=${picture_list}
    ...    append=True
    ...    target_document=${OUTPUT_DIR}${/}robots${/}${order}.pdf
    Remove File    ${OUTPUT_DIR}${/}robots${/}robot.png

ZIP Folder
    Archive Folder With Zip    ${OUTPUT_DIR}${/}robots    ${OUTPUT_DIR}${/}orders.zip
    Remove Directory    ${OUTPUT_DIR}${/}robots    True

*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Create ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Archive

Task Setup          Create work folders
Task Teardown       Close the Browser


*** Variables ***
#MAIN CONFIGURATION ROBOT PAGE ELEMENTS
${HEAD TYPE LIST ELEMENT}                       //*[@id="head"]
${RESET HEAD TYPE ID}                           0
${BODY ELEMENT}                                 //div[@class='stacked']
${INPUT TEXT LEGS NUMBER ELEMENT}               //*[@placeholder='Enter the part number for the legs']
${INPUT TEXT ADDRESS ELEMENT}                   //*[@placeholder='Shipping address']
${PREVIEW ELEMENT}                              //*[@id='preview']
${ORDER ELEMENT}                                //*[@id='order']
${ROBOT PREVIEW IMAGE ELEMENT}                  //*[@id='robot-preview-image']
${ROBOT PREVIEW SHOW MODEL INFO ELEMENT}        //*[.='Show model info']
#ORDER PAGE ELEMENTS
${RECEIPT BOX ELEMENT}                          //*[@id='receipt']
${ROBOT PREVIEW IMAGE ELEMENT ORDER PAGE}       //*[@id='robot-preview-image']
${ORDER ANOTHER ROBOT ELEMENT}                  //*[@id='order-another']

#others
${OUTPUT FOLDER}                                .${/}output
${OUTPUT RECEIPT FOLDER}                        ${OUTPUT FOLDER}${/}receipts
${OUTPUT IMAGE FOLDER}                          ${OUTPUT FOLDER}${/}images


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    Download CSV order file    https://robotsparebinindustries.com/orders.csv    input    orders.csv
    ${orders_table}=    Read CSV table with headers    .${/}input${/}orders.csv
    Loop on order    ${orders_table}
    Archive Folder With Zip    ${OUTPUT RECEIPT FOLDER}    ${OUTPUT FOLDER}${/}zipped.zip
    Clean images Directory
    Clean receipt Directory


*** Keywords ***
Create workfolders
    Create Directory    ${OUTPUT IMAGE FOLDER}

Open the robot order website
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK

Download CSV order file
    [Arguments]    ${source url}    ${target folder name}    ${target filename}
    Download
    ...    ${source url}
    ...    .${/}${target folder name}${/}${target filename}

Read CSV table with headers
    [Arguments]    ${filename}
    ${table}=    Read table from CSV    ${filename}    header: true

    RETURN    ${table}

Loop on order
    [Arguments]    ${order table var}
    FOR    ${order}    IN    @{order table var}
        Select head type number    ${order}[Head]
        Select body by number    ${order}[Body]
        Insert number of legs    ${order}[Legs]
        Insert address    ${order}[Address]
        Show robot preview
        Wait Until Keyword Succeeds    10x    0.3s    Proceed with order
        Robot order receipt on pdf    ${order}[Order number]
        Robot order image screenshot    ${order}[Order number]
        Wait Until Keyword Succeeds    2x    0.5s    Go to next order
        Close the annoying modal
        #BREAK
    END

Select head type number
    [Arguments]    ${head number}
    Click Element    ${HEAD TYPE LIST ELEMENT}
    Wait Until Element Is Visible    ${HEAD TYPE LIST ELEMENT}/option[@value="6"]
    Select From List By Index    ${HEAD TYPE LIST ELEMENT}    ${head number}
    Click Element    ${HEAD TYPE LIST ELEMENT}

Select head type label reset
    Click Element    ${HEAD TYPE LIST ELEMENT}
    Wait Until Element Is Visible    ${HEAD TYPE LIST ELEMENT}/option[@value="6"]
    Select From List By Label    ${HEAD TYPE LIST ELEMENT}    -- Choose a head --
    Click Element    ${HEAD TYPE LIST ELEMENT}

Select body by number
    [Arguments]    ${body_number}
    Click Element    ${BODY ELEMENT}//*[@for='id-body-${body_number}']

Insert number of legs
    [Arguments]    ${number of legs}
    Input Text    ${INPUT TEXT LEGS NUMBER ELEMENT}    ${number of legs}

Insert address
    [Arguments]    ${order address}
    Input Text    ${INPUT TEXT ADDRESS ELEMENT}    ${order address}

Close the Browser
    Close Browser

Reset head type
    Select head type number    ${RESET HEAD TYPE ID}

Show robot preview
    Click Element    ${PREVIEW ELEMENT}
    Wait Until Element Is Visible    ${ROBOT PREVIEW IMAGE ELEMENT}

Proceed with order
    Click Element    ${ORDER ELEMENT}
    Wait Until Element Contains    ${RECEIPT BOX ELEMENT}    Receipt
    Wait Until Element Is Visible    ${ROBOT PREVIEW IMAGE ELEMENT ORDER PAGE}

Robot order receipt on pdf
    [Arguments]    ${order id}
    ${receipt_pdf_content}=    Get Element Attribute    ${RECEIPT BOX ELEMENT}    outerHTML
    Html To Pdf    ${receipt_pdf_content}    ${OUTPUT RECEIPT FOLDER}${/}receipt_order_num_${order id}.pdf
    #Log    ${receipt_pdf_content}

Robot order image screenshot
    [Arguments]    ${order id}
    ${image_filename_path}=    Set Variable    ${OUTPUT IMAGE FOLDER}${/}image_order_num_${order id}.png
    Screenshot    //*[@id='robot-preview-image']    ${image_filename_path}

    ${file_list}=    Create List    ${OUTPUT IMAGE FOLDER}${/}image_order_num_${order id}.png
    #Open Pdf    ${OUTPUT RECEIPT FOLDER}${/}receipt_order_num_${order id}.pdf
    Add Files To Pdf
    ...    ${file_list}
    ...    ${OUTPUT RECEIPT FOLDER}${/}receipt_order_num_${order id}.pdf
    ...    ${True}
    #Close Pdf    ${OUTPUT RECEIPT FOLDER}${/}receipt_order_num_${order id}.pdf

Go to next order
    Click Element    ${ORDER ANOTHER ROBOT ELEMENT}

Clean images Directory
    Empty Directory    ${OUTPUT IMAGE FOLDER}

Clean receipt Directory
    Empty Directory    ${OUTPUT RECEIPT FOLDER}

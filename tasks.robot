*** Settings ***
Library     RPA.Browser.Selenium    auto_close=${FALSE}
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.FileSystem
Library     RPA.Archive


*** Variables ***
${img_folder}       ${CURDIR}${/}image_files
${pdf_folder}       ${CURDIR}${/}pdf_files
${output_folder}    ${CURDIR}${/}output

${orders_file}      ${CURDIR}${/}orders.csv
${zip_file}         ${output_folder}${/}pdf_archive.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    # WHILE    True
    Directory Cleanup
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill The form    ${row}
        Wait Until Keyword Succeeds    10x    1s    Preview the robot
        Wait Until Keyword Succeeds    10x    1s    Submit The Order
        ${orderid}    ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file    IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Create a Zip File of the Receipts
    Close Browser
    # END


*** Keywords ***
Directory Cleanup
    Log To console    Cleaning up content from previous test runs

    # Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}

    Empty Directory    ${img_folder}
    Empty Directory    ${pdf_folder}
    # Empty Directory    ${output_folder}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/
    Click Link    Order your robot!

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv    target_file=${orders_file}    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Close the annoying modal
    # Define local variables for the UI elements
    # Set Local Variable    ${btn_yep}    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]

Fill The form
    [Arguments]    ${orders}
    Select From List By Value    id:head    ${orders}[Head]
    Click Element    id:id-body-${orders}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]

Preview the robot
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order
    Click Button    id:order
    Page Should Contain Element    id:receipt

Go to order another robot
    Click Button    id:order-another

Take a screenshot of the robot
    Wait Until Element Is Visible    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Wait Until Element Is Visible    robot-preview-image

    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${fully_qualified_img_filename}    ${img_folder}${/}${orderid}.png
    Sleep    1sec
    Log To Console    Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot    robot-preview-image    ${fully_qualified_img_filename}
    RETURN    ${orderid}    ${fully_qualified_img_filename}

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}

    Wait Until Element Is Visible    //*[@id="receipt"]
    Log To Console    Printing ${ORDER_NUMBER}
    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML

    Set Local Variable    ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf

    Html To Pdf    content=${order_receipt_html}    output_path=${fully_qualified_pdf_filename}
    RETURN    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    Log To Console    Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}
    Open PDF    ${PDF_FILE}
    @{myfiles}=    Create List    ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}    ${True}
    Close PDF    ${PDF_FILE}

Create a Zip File of the Receipts
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Log Out And Close The Browser
    Close Browser

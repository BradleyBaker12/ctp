# patch notes

27/08/2024

Updated Logo for all truck brands
Add better spacing between the text
Fix the truck cards on the truck page to look more like a card
Moved the text and buttons under the image to look more visible
Adding the unswipe feature, if the user has made a mistake on a swipe
Added an ellipses to the vehicle name if it's too long
The file change, the icon sits on top of the file name now
The user can edit their new updated profile image to fix the rotation and size of to crop as well
Added blue box on the sides of the truck cards on the home page
The adjust offer page functionality is working now, but still needs a few design adjustments

28/08/2024

Fixed the spacing on the offer cards
Fixed the spacing on the wishlist cards
Waiting to see if the API for google maps android has been reset takes about 24h hours, can check again tomorrow at 12ish.
Fixed the designs for the report an issue and thank you pages
Updated report issue pages
Fixed sapcing on certain pages to look more like designs

29/08/2024
Fixing the Truck and Trailer buttons on the home page
Added the forgot password to the signin screen
Added honesty bar to the vehicle cards on the home page

30/08/2024
Fixed the appbar alignment of the CTP Logo and the profile image
Fixed the colouring of the input text
Fixed the phone number page
Add the logo to the prefered Brands screen
Updated icons on dealer reg page to look more like the design
Added updated logo's to the homep page
The following pages were made even more responsive:
Login Page, sign up page,

02/09/2024
Aligned the headings to the left on the inspection waiting page
"Great News!" Text adjusted to match designs
An issue with the offer card navigation based on offer status came up where the card would not navigate and has been resolved
Changes the date format to have a more readable look
Made adjustments to all number involving currency. The currency is not more readable
Added an Appbar to the wishlist and offers page
Adjust the layout of the wishlist page to be more like the design
Add view all button to the wishlist and pending offers section so the user can view all thir offers and wishlisted vehicles
Added a cancle button on the sign up page
Fixed the navigation to the transporter registartion page

03/09/2024
removed the heart picture on the wishlist and pending offers screen
The profile icon was removed in the bottom navigation and replaced with the pending offers page
Added appbar to all pages
Profile icon in app bar takes the user to the profile page
Fixed the issue where the overlay was preventing ther user from enlarging the image on the truck card
Fixed the prefered brands filter so that the truck displayed are now based on the brands the user likes

04/09/2024
Fixed the navbar to render certain things for the dealer and certain things for the transporter
Fixed the offer card for the transporter to look more like the design
Add an accept or reject page for the transporter to view and accepted or reject the offer
Changes the Image on the login screen to the new design
Made the login page scrollable for devices are doen't fall into the normal screen constaints
Made changes to transporter side, add all changes to the truck upload form

05/09/2024
Added a scroll bar to the edit brands on the home page
Added a remove vehilce from wishlist when the user swipes left on the card
Fixed missing fiedls from the transporter upload truck forms
Fixed the dropdown list to show the hint text before the user selects their options
Add conditional rendering based on a yes/no selection from the user which will show text boxes for either reasoning or more informaiton
Changes the warranty title to "Is it under a warranty"

06/09/2024
Fixed the issue were the data wasn't being pulled properly on the wish card

09/09/2024
Adjusting the wishlist card so that vehilce with offers will say that they have an offer
Trying to fix image's not loading on wishcard lists
Starting to add new CTP Loader to all pages

10/09/2024
Added inspection setup button and form for transporter to setup the locaiton , date and time for inspection

11/09/2024
Some vehilce were not showing on the vehicle list page, fixed that issue
Images were not showing on the vehilce details page, fixed that as well
Styled the vehilce listing page to look more like the designs
Setup the inspection and collection allocaiton the transporter needs to provider

12/09/2024
Adding drawer to transporter forms so that the user can travel freely between the form section
Fixing the structure of the form so that it rememebers where the user last left off on the form

13/09/2024
Fixing the structure of the form so that it rememebers where the user last left off on the form

15/09/2024-17/09/2024
setup location, dates and times for the dealer size once the transporter has set the locations, dates and times.

17/09/2024
Under the "Your vehicles with offers", it need to be respective to the user. So the vehicles displayed are only those that belong to the transporter and that have offers on them and they should match the the offer being displayed under it.
on the faults where you can upload all the damages to the truck, it needs to be a yes , no for all section, if you press no then it takes the block away.
When filling in the Truck/Tyre section it needs to be displayed like that, currently they are filling out the tyre section and it says Truck/Trailer.
Describe the damages needs to be a section where they add a picture of the damage with a photo and text and that can be repeated multiple times.

18/09/2024 - 23/09/2024
Refactored the truck form so the user can move between each section of the form freely and that the data is saved for that truck

24/09/2024
After refacotirng the truck form we needed to fix the vehilce listing page so that it can relfect the users uploaded trucks form that form.
Adjustments made to the truck form so that it is more readable
Made the setup for the inspection detaisl and collection details more user friendly in a functinality point of view, designs need more adjuments
Added pagination to the my vehicles page
make sure the hitbox of the yes and no is bigger and the truck drivers focusing on the little dot that they need to press on is too small

26/09/2024
Changed the handshake icon in the bottom navigation to be more like the design
Offers on trucks we need tabs for, ALL, PENDING. ACCEPTED and IN-PROGRESS
Createing the edit for for users to edit the vehicle details

27/09/2024
Fixing and adjusted the edit form, still needs styling added
Add a label to images so the user knowns which image they are on
upload an image or video on the inspection for report an issue
scrolling up and down when you're on the calendar doesn't work properly
Brandon tried to upload the last photo and it just kicked him to the home screen of the app and he can't get back to the form because the edit form button is under the S7s buttons at the bottom.
All the offers are coming through on the transporter home screen , even ones that aren't his, it needs to be specific for a user
Images are buggy on the wish - list screen, all the information says N/A when you click on the truck and want to view it.
double check trailer form, make sure there are enough blocks for images for the trailers
Made he edit button only visible to transporter
Moved the Setup Inspection and Setup Collection button to after the user has accepted the offer. Still need to add/move all proper functinality to those buttons and pages

01/10/2024
Need to be able to select another date if you select the wrong date. At the moment they need to select a time first
inspection dates needs to be after accepting an offer
Adding conditional redenering for user roles between dealer and transporter.
Added the approval screen for the transporter (Approve inspection, rate dealer)
Fixed the collection and inspection dates, location and times to be after the offer has been accepted
Waiting to see if the Maps works on andriod. Changed the API so that it works on android specificly

02/10/2024
Added headings to all radio buttons
Added "Is vehilce avaliable immediatly" wuth a yes or no and they can select the date for when it is ready to be sold if they select no
Made sure that all recent offers are shown first, ordered lastest first
Added the feaeture where the locations are saved, just need to test it properly to see if it works
Busy trying to add the duplicate feature

04/10/2024
Add all the offers under the trucks details screen
Moving some input field to the mandatory page

07/10/2024
Moved some input field to the mandatory page
Completed the Duplication added
The Apps Icon has been changed and is now the CTP Logo
Changed the Display name to CTP
Added radio buttons to conditionaly show certain tabs
Certain Tab's are shown based on what the user selected (Yes/No)

08/10/2024
Fixed the Edit Form so that the user can now edit most of the uploaded information
Hide any offers that have been completed fully

14/10/2024
Make the Tab on the pending offers page scrollable for devives that are unsupported and repsoinsive for all devices
Added a delete option
Edited Items shouldn't be duplicated anymore (just needs for testing)
Vehilces on the dealer side should not see vehicles on the dealer side
Add a rejected Tab so that the dealer is able to see that they have vehilce offers that have been rejected

15/09/2024
Removed the extra dashboard and license disk upload

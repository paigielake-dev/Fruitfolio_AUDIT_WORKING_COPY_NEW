# Actual Run64 shared-control result and largest-text follow-up

At source db650d9, normal Contact navigation passed (38.940 s), FAQ at Accessibility XXXL passed (35.649 s), and normal FAQ expand/collapse passed (39.862 s). The Contact largest-text test failed the unchanged native contrast audit on the real TikTok StaticText. The native Button now has its full correct name, and the actual visible Text is exposed; this is a different remaining issue from Run61 unnamed Buttons.

The actual label spans three large wrapped lines, including the social platform, bullet and handle. Screenshots and AX bounds are retained. Largest-text contact actions now present those three semantic parts as real separate text blocks, each with intrinsic bounds and unchanged words. The complete exact original accessible action name stays on the actual Button. Normal-size layout/artwork/colors remain unchanged. No text is hidden and no audit issue is filtered or accepted away. Actual rerun determines whether the contrast issue is resolved.

Run66's same upstream Hub/vine implementation is retained and its actual 533-test unit artifact has been downloaded and SHA/CRC verified. CI may supersede that older duplicate full traversal after inventorying metadata; its pending UI stages are NOT VERIFIED. Run64 focused repaired-label journeys continue, and the latest source reruns the complete suite.

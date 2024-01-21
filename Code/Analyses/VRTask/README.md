# VRCC - Analyses
**Code authors:**  
Felix Klotzsche, Pawel Motyka, Aleksander Molak </font>  
*klotzsche@cbs.mpg.de*  
*pmotyka@psych.pan.pl*  
*aleksander.molak@gmail.com*

# Folders
| Folder   | Description |
|----------|-------------|
| `\Cardio` | MATLAB scripts for preprocessing of the ECG data (filtering, R Peak detection, cleaning). <br> This should normally not be necessary to re-run (and includes manual steps). We recommend to directly use the preprocessed data. |
| `\Figures` | High-res figures for the manuscript. |
| `\Python` | Python notebooks for analyzing the data of the online stimulus prerating and to produce circular plots. |
| `\Utils` | R helper functions.


# Notebooks
| File | Description |
|--------|-------------|
| `VRCC_main_analysis.Rmd` | **Statistical analysis of the main, pre-registered hypotheses and tests:** <br> - Data checks and descriptive statistics of dep. variables <br> - Hypothesis 1: Comparison of distance error between threatening and non-threatening objects <br> - Hypothesis 2: Comparison of distance error between cardiac phases <br> - Comparison of distance error between cardiac phases (individual animals) <br> - Distance errors as a function of true distance (individual animals) <br> - Width of distance error distributions as function of threat and cardiac phase  <br> (Reads the output from `VRCC_preprocessing.Rmd` which we provide in `\Data\VRTask\VRCC_data_consolidated-2023-08-10.csv`.)|
| `VRCC_exploratory_analysis.Rmd` | **Additional exploratory and control analyses:** <br> - Comparison of localization error between cardiac phases<br> - RR interval length and distance estimates <br> - Animal assessment <br> - threat, disgust, and speed ratings<br> - Distance error as a function of subjective threat<br> - Distance error as a function of anxiety levels, disgust, and speed ratings<br> - Cybersickness (SSQ) and presence in VR (SUS)<br> - Distance errors as a function of real distance<br> - Distribution of stimulus onsets across the cardiac cycle|
| `VRCC_preprocessing.Rmd` | **Final steps of the preprocessing:** <br> - Compute distance measures <br> - Determine cardiac phases <br>- Exclusions based on localization errors (individual trials) <br> - Exclusions based on distance errors (individual subjects) <br> - Exclusions based on cardiac data (individual trials) <br> - Remove identified trials and save the preprocessed data
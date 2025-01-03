

![VME](./VRCC_header_v0.2.png)

<h2>VRCC – No cardiac phase bias for threat-related threat perception in immersive virtual reality </h2>

📖 **Publication:**  [Klotzsche*, Motyka* et al. (2024, Royal Sociaty Open Science)](https://royalsocietypublishing.org/doi/full/10.1098/rsos.241072)

💽 **Data:** https://doi.org/10.17617/3.KJGEZQ 

📑 **Preprint:** https://www.biorxiv.org/content/10.1101/2024.01.31.578172v1  
  
🐺 **Demo of the VR experiment**: https://osf.io/a7n9b/

<a href="https://royalsocietypublishing.org/doi/full/10.1098/rsos.241072" target="_blank">
    <img src="https://github.com/user-attachments/assets/d9043f79-cbb6-4c3c-bae2-a5f31f030076" alt="Clickable Image" style="max-width:100%;">
</a>

<br/><br/>
[![R.pm](https://img.shields.io/badge/R->4.1-informational.svg?maxAge=259200)](#)
[![Python.pm](https://img.shields.io/badge/python-3.8-blue.svg?maxAge=259200)](#)
[![version](https://img.shields.io/badge/version-0.1-yellow.svg?maxAge=259200)](#)

<h2>Introduction</h2>

Combining ECG with immersive virtual reality, we studied whether the cardiac phase influences the distance perception of threatening and non-threatening animals. 


<h2>Instructions</h2>

If you want to reproduce the statistics (or the [pre]processing steps) reported in the paper, we suggest that you follow these steps: 

> **Shortcuts**  
Code relevant for the ECG (pre)processing can be found in [/Code/Analyses/VRTask/Cardio/Preprocessing](/Code/Analyses/VRTask/Cardio/Preprocessing).  
Most of the main statistical analysis are performed in [/Code/Analyses/VRTask/VRCC_main_analysis.Rmd](/Code/Analyses/VRTask/VRCC_main_analysis.Rmd), further notebooks with exploratory analyses and the preprocessing can be found in [/Code/Analyses/VRTask](/Code/Analyses/VRTask).  
All relevant subfolders contain separate README files with concrete explanations.

> **Most important**  
If you run into problems, please do not hesitate to contact us (e.g., via email) or open an issue here. Much of the code is acceptably well documented and the notebooks should (theoretically) run from top to bottom.  
So if you want to work with the code, we are happy to support you in getting it to work.
  
**How to get started:**   
1. Download the data set from [Edmond – The Open Research Data Repository of the Max Planck Society](https://doi.org/10.17617/3.KJGEZQ)  
    There are data-readme files on Edmond which explain what the single folders and files contain.
2. Clone this repository to a clean local directory. 
3. Replace the `\Data` folder with the actual data which you downloaded in step 1 and unzipped. 
4. Now you should be ready to go. 😊



<h2>Versions</h2>  

> You can use the `tags` in the repo to identify the according commits.

###### v1.0
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.13797560.svg)](https://doi.org/10.5281/zenodo.13797560)  
`2024-09`: Code associated with the peer-reviewed publication  
* <a href="https://royalsocietypublishing.org/doi/full/10.1098/rsos.241072">  Klotzsche*, Motyka*, Molak, Sahula, Darmová, Byrnes, Fajnerová, Gaebler, <i>RSOS</i>, 2024</a>

###### v0.1
`2024-01`: Code associated with the preprint:
* <a href="https://www.biorxiv.org/content/10.1101/2024.01.31.578172v1">  Klotzsche*, Motyka*, Molak, Sahula, Darmová, Byrnes, Fajnerová, Gaebler, <i>bioRxiv</i>, 2024</a>

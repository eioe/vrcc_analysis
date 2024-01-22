

![VME](./VRCC_header_v0.2.png)

<h2>VRCC – No cardiac phase bias for threat perception under naturalistic conditions in immersive virtual reality </h2>

💽 **Data:** https://doi.org/10.17617/3.KJGEZQ 

📑 **Preprint:** [to be replaced with bioRxiv link] 

🐺 **Demo of the VR experiment**: https://osf.io/a7n9b/

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


###### v0.1
`2024-01`: Code associated with the preprint:
* <a href="">  Klotzsche*, Motyka*, Molak, Sahula, Darmová, Byrnes, Fajnerová, Gaebler, <i>bioRxiv</i>, 2024</a>

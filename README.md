# DSP-MatConvNet

This package is a MatConvNet implementation of ["Deep Spatial Pyramid: The Devil is Once Again in the Details",Bin-Bin Gao, Xiu-Shen Wei, Jianxin Wu, Weiyao Lin](https://arxiv.org/abs/1504.05277). You can extract DSP features and train svm model for image classification on your own dataset with pre-trained CNN models. This package is created by [Bin-Bin Gao](http://lamda.nju.edu.cn/gaobb/).

### Table of Contents
0. [Requirements & Install](#Requirements-Install)
0. [Download Models & Datasets](#Download-Models&Datasets)
0. [Run Single-scale DSP](#Single-scale-DSP)
0. [Run Multi-scale DSP](#Multi-scale-DSP)
0. [Additional Information](#Additional-Information)

### Requirements & Install
The following software should be downloaded and built before running the experiments.

0. [MATLAB](https://mathworks.com/products/matlab.html).
    - version: matlab 2014b or matlab 2016b

0. [Install]()
    - You can clone the package and install it through the following command in linux terminal:
      ```
      $ git clone --recurse-submodules git@github.com:gaobb/DSP.git
      $ cd DSP/
      $ matlab -nodisplay -r "setup(true,struct('enableGpu',true,'enableCudnn',true));exit;"
      ```

0. [vlfeat](http://www.vlfeat.org/) is used for FV or VLAD encoding. (included in this package, see `external/vlfeat`)
    - version: vlfeat-0.9.19
    - If you have problem with compiling Vlfeat, please refer to the [link](http://www.vlfeat.org/compiling.html).
    
0. [matconvnet](http://www.vlfeat.org/matconvnet/) is used for extracting deep features based on pre-trained model.(included in this package, see `external/matconvnet`)
    - version: matconvnet-1.0-beta24
    - If you have problem with compiling MatConvNet, please refer to the [link](http://www.vlfeat.org/matconvnet/install/).

0. [DenseLibLinear](https://github.com/gaobb/DenseLIBLINEAR) is used for train svm classification model.(included in this package, see `external/DenseLibLinear`)



### Download pre-trained model and datasets
You can download some powerful cnn models from the [link](http://www.vlfeat.org/matconvnet/pretrained/).

- the models to `pre_models` : 

  [imagenet-vgg-verydeep-16](http://www.vlfeat.org/matconvnet/models/imagenet-vgg-verydeep-16.mat)

  [imagenet-vgg-verydeep-19](http://www.vlfeat.org/matconvnet/models/imagenet-vgg-verydeep-19.mat)

  [imagenet-resnet-50-dag](http://www.vlfeat.org/matconvnet/models/imagenet-resnet-50-dag.mat) 

  [imagenet-resnet-101-dag](http://www.vlfeat.org/matconvnet/models/imagenet-resnet-101-dag.mat) 

  [imagenet-resnet-152-dag](http://www.vlfeat.org/matconvnet/models/imagenet-resnet-152-dag.mat) 

- the datasets to `datasets/` : 

  [The PASCAL VOC](http://host.robots.ox.ac.uk/pascal/VOC/)

  [MIT Places Database](http://places.csail.mit.edu/)

### Single-scale DSP
```matlab
run_dsp_svm
```
### Multi-scale DSP
```matlab
run_mdsp_svm
```
### Additional Information
If you find DSP helpful, please cite it as
```
@article{gao2015deep,
  title={Deep spatial pyramid: The devil is once again in the details},
  author={Gao, Bin-Bin and Wei, Xiu-Shen and Wu, Jianxin and Lin, Weiyao},
  journal={CoRR, abs:1504.05277},
  year={2015}
}

@inproceedings{wu2016representing,
  title={Representing Sets of Instances for Visual Recognition.},
  author={Wu, Jianxin and Gao, Bin-Bin and Liu, Guoqing},
  booktitle={Proceedings of the 30th AAAI Conference on Artificial Intelligence},
  pages={2237--2243},
  year={2016}
}
```

ATTN1: This packages are free for academic usage. You can run them at your own risk. For other
purposes, please contact Prof. Jianxin Wu (wujx2001@gmail.com).


ATTN2: This packages were developed by Bin-Bin Gao.
For any problem concerning the code, please feel free to contact Bin-Bin Gao (csgaobb@gmail.com).

> version: Apr. 14, 2017


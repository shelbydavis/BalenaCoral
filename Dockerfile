FROM balenalib/raspberrypi3-debian-python:3.6-buster-build
# enable access to the USB ports
ENV UDEV=1
ENV TensorFlow_Version=1.15.0

# Install the Coral drivers
RUN echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | tee /etc/apt/sources.list.d/coral-edgetpu.list && \
    curl -s -L https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    install_packages libedgetpu1-std && \
    python3.6 -m pip install --upgrade pip setuptools wheel && \
    python3.6 -m pip install numpy Pillow

# Download and build tensorflow lite
RUN install_packages unzip swig && \
    curl -s -L https://github.com/tensorflow/tensorflow/archive/v${TensorFlow_Version}.tar.gz | tar xzf - && \
#    bash /tensorflow-${TensorFlow_Version}/tensorflow/lite/tools/make/download_dependencies.sh && \
#    bash /tensorflow-${TensorFlow_Version}/tensorflow/lite/tools/make/build_rpi_lib.sh && \
    cd /tensorflow-${TensorFlow_Version}/tensorflow/lite/tools/pip_package && \
    bash build_pip_package.sh && \
    python3.6 -m pip install --upgrade /tmp/tflite_pip/python/dist/tflite_runtime-${TensorFlow_Version}-cp36-cp36m-linux_armv7l.whl && \
    cd / && rm -rf /tmp/tflite_pip /tensorflow-${TensorFlow_Version}

# Download the tflite coral examples
RUN mkdir coral && cd coral && \
    git clone https://github.com/google-coral/tflite.git && \
    bash /coral/tflite/python/examples/classification/install_requirements.sh

WORKDIR /coral/tflite/python/examples/classification/

ENTRYPOINT ["python3"]
CMD ["classify_image.py", "--model", "models/mobilenet_v2_1.0_224_inat_bird_quant_edgetpu.tflite", "--labels", "models/inat_bird_labels.txt", "--input", "images/parrot.jpg"]
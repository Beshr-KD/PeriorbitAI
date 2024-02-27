const imageInput = document.getElementById('imageInput');
const uploadButton = document.getElementById('uploadButton');
const displayButton = document.getElementById('displayButton');
const imageContainer = document.getElementById('imageContainer');

let uploadedImage = null;

uploadButton.addEventListener('click', () => {
    imageInput.click();
});

imageInput.addEventListener('change', () => {
    const file = imageInput.files[0];
    const reader = new FileReader();

    reader.onload = () => {
        uploadedImage = reader.result;
        alert('Image uploaded successfully!');
    };

    if (file) {
        reader.readAsDataURL(file);
    }
});

displayButton.addEventListener('click', () => {
    if (uploadedImage) {
        const imgElement = document.createElement('img');
        imgElement.setAttribute('src', uploadedImage);
        imgElement.setAttribute('id', 'uploadedImage');
        imageContainer.innerHTML = '';
        imageContainer.appendChild(imgElement);
    } else {
        alert('Please upload an image first!');
    }
});
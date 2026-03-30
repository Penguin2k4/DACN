import os
import io
import numpy as np
import tensorflow as tf
from PIL import Image
from tensorflow.keras.models import load_model, Model, Sequential
from tensorflow.keras import layers
from tensorflow.keras.applications import EfficientNetV2B1

# ==============================================================================
# 1. CÁC HÀM CHO MODEL CŨ (HYBRID CUSTOM)
# ==============================================================================
def eca_block(x):
    channels = x.shape[-1]
    se = layers.GlobalAveragePooling2D()(x)
    se = layers.Reshape((1, 1, channels))(se)
    se = layers.Conv2D(1, (1, 1), padding='same', use_bias=True)(se)
    se = layers.Activation('sigmoid')(se)
    return layers.Multiply()([x, se])

def spatial_attention(x):
    att = layers.Conv2D(1, (7, 7), padding='same', activation='sigmoid')(x)
    return layers.Multiply()([x, att])

def mixed_depthwise_conv(x, filters=None):
    channel_axis = -1
    in_channels = x.shape[channel_axis]
    split_pt = in_channels // 2
    def split_func(t):
        return tf.split(t, num_or_size_splits=[split_pt, in_channels - split_pt], axis=channel_axis)
    splits = layers.Lambda(split_func, name="split_lambda")(x)
    g1_in, g2_in = splits[0], splits[1]
    g1 = layers.DepthwiseConv2D((3, 3), padding='same', use_bias=False)(g1_in)
    g2 = layers.DepthwiseConv2D((5, 5), padding='same', use_bias=False)(g2_in)
    out = layers.Concatenate(axis=channel_axis)([g1, g2])
    out = layers.Conv2D(filters if filters else in_channels, (1, 1), padding='same', use_bias=False)(out)
    out = layers.BatchNormalization()(out)
    out = layers.Activation('swish')(out)
    return out

# ==============================================================================
# 2. HÀM BUILD MODEL
# ==============================================================================

def build_hybrid_model(backbone_type='efficientnet', input_shape=(224, 224, 3), num_classes=12):
    inputs = layers.Input(shape=input_shape)
    if backbone_type == 'mobilenet':
        base = tf.keras.applications.MobileNetV2(input_shape=input_shape, include_top=False, weights=None)
        x = base(inputs)
        x = mixed_depthwise_conv(x, filters=x.shape[-1])
        x = eca_block(x)
        x = spatial_attention(x) 
        x = layers.GlobalAveragePooling2D()(x) 
    else: # EfficientNet Hybrid
        base = EfficientNetV2B1(input_shape=input_shape, include_top=False, weights=None)
        x = base(inputs)
        x = mixed_depthwise_conv(x, filters=x.shape[-1])
        x = eca_block(x)
        x = spatial_attention(x)
        x = layers.Flatten()(x)
    x = layers.Dense(512, activation='swish')(x)
    x = layers.Dropout(0.4)(x)
    outputs = layers.Dense(num_classes, activation='softmax')(x)
    return Model(inputs=inputs, outputs=outputs)

def build_kaggle_standard_model(input_shape=(224, 224, 3), num_classes=12):
    base_model = EfficientNetV2B1(
        input_shape=input_shape,
        include_top=False,
        weights=None 
    )
    base_model.trainable = False
    
    model = Sequential([
        base_model,
        layers.Flatten(),
        layers.Dropout(0.5),
        layers.Dense(num_classes, activation='softmax')
    ])
    return model

# ==============================================================================
# 3. CLASS PREDICT SERVICE
# ==============================================================================
class PredictService:
    LABELS = [
        "battery", "biological", "brown-glass", "cardboard", "clothes",
        "green-glass", "metal", "paper", "plastic", "shoes",
        "trash", "white-glass"
    ]
    
    def __init__(self):
        print("🔄 Đang khởi tạo PredictService...")
        current_dir = os.path.dirname(os.path.abspath(__file__))
        base_dir = os.path.dirname(current_dir)
        
        # Đường dẫn weights
        path_eff_custom = os.path.join(base_dir, "ml_models", "effica2custom(2)hybird.h5")
        path_mobile_custom = os.path.join(base_dir, "ml_models", "mobilenetv2_plus_mostafa_12class2.h5")
        
        # File Kaggle (Đuôi .keras)
        path_eff_kaggle = os.path.join(base_dir, "ml_models", "Efficientnetv2b1(base)_kaggle (1).keras")
        
        self.models = {}
        
        # 1. Load Custom MobileNet
        if os.path.exists(path_mobile_custom):
            try:
                print(f"⏳ Loading Custom MobileNet...")
                mb = build_hybrid_model('mobilenet', num_classes=len(self.LABELS))
                mb(np.zeros((1, 224, 224, 3)))
                mb.load_weights(path_mobile_custom)
                # Tên key khớp với Flutter: mobilenetv2_plus
                self.models["mobilenetv2_plus"] = mb
                print("✅ Done MobileNet Custom")
            except Exception as e: print(f"❌ Err MB: {e}")

        # 2. Load Custom EfficientNet
        if os.path.exists(path_eff_custom):
            try:
                print(f"⏳ Loading Custom EfficientNet...")
                eff = build_hybrid_model('efficientnet', num_classes=len(self.LABELS))
                eff(np.zeros((1, 224, 224, 3)))
                eff.load_weights(path_eff_custom)
                # Tên key khớp với Flutter: effica2custom(2)hybird
                self.models["effica2custom(2)hybird"] = eff
                print("✅ Done EfficientNet Custom")
            except Exception as e: print(f"❌ Err EffCustom: {e}")

        # 3. Load Kaggle Standard EfficientNet
        if os.path.exists(path_eff_kaggle):
            try:
                print(f"⏳ Loading EfficientNet Kaggle: {path_eff_kaggle}")
                eff_kag = build_kaggle_standard_model(num_classes=len(self.LABELS))
                eff_kag(np.zeros((1, 224, 224, 3))) 
                eff_kag.load_weights(path_eff_kaggle)
                
                # --- [QUAN TRỌNG] ĐẶT TÊN KEY LÀ 'efficientnetv2b1' ĐỂ KHỚP VỚI FLUTTER ---
                self.models["efficientnetv2b1"] = eff_kag 
                print("✅ Done efficientnetv2b1 (Kaggle Model)")
            except Exception as e: print(f"❌ Err EffKaggle: {e}")

    def _preprocess_image(self, image_bytes, model_name):
        try:
            img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            img = img.resize((224, 224))
            arr = np.array(img)
            
            # --- LOGIC XỬ LÝ ẢNH MỚI ---
            # 1. Model Kaggle (Tên key là 'efficientnetv2b1')
            # Model này tự chuẩn hóa bên trong, KHÔNG ĐƯỢC chia 255.
            if "efficientnetv2b1" in model_name.lower():
                print(f"🔍 Preprocessing: Giữ nguyên [0-255] cho {model_name}")
                arr = arr.astype('float32') 
                
            # 2. Các model cũ (Custom Hybrid)
            # Các model này cần chia 255 để về [0-1].
            else:
                print(f"🔍 Preprocessing: Chia 255 [0-1] cho {model_name}")
                arr = arr.astype('float32') / 255.0
            
            arr = np.expand_dims(arr, axis=0)
            return arr
        except Exception as e:
            raise e

    def predict_image(self, image_bytes, model_name):
        # Logic chọn model
        target_key = None
        for key in self.models.keys():
            if model_name.lower() in key.lower():
                target_key = key
                break
        if target_key is None:
             if self.models:
                 target_key = list(self.models.keys())[0]
                 print(f"⚠️ Không tìm thấy '{model_name}', dùng thay thế: {target_key}")
             else:
                 raise ValueError("Không có model nào được load!")

        try:
            model = self.models[target_key]
            tensor = self._preprocess_image(image_bytes, target_key)

            preds = model.predict(tensor)
            preds = preds[0]
            idx = int(np.argmax(preds))
            confidence = float(preds[idx])
            label = self.LABELS[idx] if idx < len(self.LABELS) else "Unknown"
            
            print(f"🎯 Result ({target_key}): {label}")
            return {"model": target_key, "label": label}
        except Exception as e:
            print(f"❌ Prediction Error: {e}")
            raise e
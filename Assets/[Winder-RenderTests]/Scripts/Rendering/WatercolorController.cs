using UnityEngine;

namespace RoyTheunissen.Winder.Rendering
{
    [ExecuteInEditMode]
    public class WatercolorController : MonoBehaviour
    {
        [SerializeField] private Texture2D lightRamp;
        [SerializeField] private Texture2D perlinTexture;
        
        private void Awake()
        {
            ApplyRenderSettings();
        }
        
        private void Update()
        {
            ApplyRenderSettings();
        }

        private void ApplyRenderSettings()
        {
            if (lightRamp != null)
                Shader.SetGlobalTexture("_LightRampTex", lightRamp);
            
            if (perlinTexture != null)
                Shader.SetGlobalTexture("_PerlinTex", perlinTexture);
        }
    }
}

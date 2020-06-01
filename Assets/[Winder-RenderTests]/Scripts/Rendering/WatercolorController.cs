using UnityEngine;

namespace RoyTheunissen.Winder.Rendering
{
    [ExecuteInEditMode]
    public class WatercolorController : MonoBehaviour
    {
        [SerializeField] private Texture2D lightRamp;
        [SerializeField] private Texture2D perlinTexture;
        [SerializeField] private Texture2D uvTestTexture;
        
        [Space]
        [SerializeField, ColorUsage(false, true)] private Color additiveAmbientLight;
        
        [Space]
        [SerializeField, ColorUsage(false, true)] private Color windingColorSelection;
        [SerializeField, ColorUsage(false, true)] private Color windingColorPositive;
        [SerializeField, ColorUsage(false, true)] private Color windingColorNegative;
        [SerializeField, ColorUsage(false, true)] private Color windingColorNeutral;

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
            
            if (uvTestTexture != null)
                Shader.SetGlobalTexture("_UvTestTex", uvTestTexture);
            
            Shader.SetGlobalColor("_AdditiveAmbientLight", additiveAmbientLight);
            
            Shader.SetGlobalColor("_WindingColorSelection", windingColorSelection);
            Shader.SetGlobalColor("_WindingColorPositive", windingColorPositive);
            Shader.SetGlobalColor("_WindingColorNegative", windingColorNegative);
            Shader.SetGlobalColor("_WindingColorNeutral", windingColorNeutral);
        }
    }
}

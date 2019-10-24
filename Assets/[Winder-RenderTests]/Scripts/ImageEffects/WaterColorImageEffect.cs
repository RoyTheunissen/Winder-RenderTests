using UnityEngine;

namespace UnityStandardAssets.CinematicEffects
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    [AddComponentMenu("Image Effects/Water Color")]
    public class WaterColorImageEffect : MonoBehaviour
    {
        [SerializeField]
        private Shader m_Shader;
        public Shader shader
        {
            get
            {
                if (m_Shader == null)
                    m_Shader = Shader.Find("Hidden/WaterColorImageEffect");

                return m_Shader;
            }
        }

        private Material m_Material;
        public Material material
        {
            get
            {
                if (m_Material == null)
                    m_Material = ImageEffectHelper.CheckShaderAndCreateMaterial(shader);

                return m_Material;
            }
        }
        
        [SerializeField] private Texture2D valueRampTexture;
        [SerializeField] private Texture2D paperTexture;

        private RenderTextureUtility m_RTU;

        private void OnEnable()
        {
            if (!ImageEffectHelper.IsSupported(shader, false, false, this))
                enabled = false;

            m_RTU = new RenderTextureUtility();
        }

        private void OnDisable()
        {
            if (m_Material != null)
                DestroyImmediate(m_Material);

            m_Material = null;
            m_RTU.ReleaseAllTemporaryRenderTextures();
        }

        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            if (!enabled)
            {
                Graphics.Blit(source, destination);
                return;
            }
            
            material.SetTexture("_ValueRampTex", valueRampTexture);
            material.SetTexture("_PaperTex", paperTexture);

            Graphics.Blit(source, destination, material);

            m_RTU.ReleaseAllTemporaryRenderTextures();
        }
    }
}

using UnityEngine;

namespace RoyTheunissen.Winder.Rendering
{
    /// <summary>
    /// 
    /// </summary>
    public sealed class WindingParticles : MonoBehaviour
    {
        [SerializeField] private new ParticleSystem particleSystem;
        [SerializeField] private Transform target;
        [SerializeField] private float lifetimeNormalizedMin = 0.4f;
        [SerializeField] private float lifetimePerDistance = 4;
        [SerializeField] private float lifetimeExtra = 1;

        private void Update()
        {
            float distance = Vector3.Distance(particleSystem.transform.position, target.position);
            
            ParticleSystem.MainModule mainModule = particleSystem.main;
            
            ParticleSystem.MinMaxCurve startLifetime = mainModule.startLifetime;
            startLifetime.constantMax = distance * lifetimePerDistance + lifetimeExtra;
            startLifetime.constantMin = startLifetime.constantMax * lifetimeNormalizedMin;
            mainModule.startLifetime = startLifetime;
        }
    }
}

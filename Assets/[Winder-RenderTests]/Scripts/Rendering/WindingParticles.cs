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
        
        [Space]
        [SerializeField] private float lifetimeNormalizedMin = 0.4f;
        [SerializeField] private float lifetimePerDistance = 4;
        [SerializeField] private float lifetimeExtra = 1;
        
        [Space]
        [SerializeField, Range(0.5f, 5.0f)] private float coreSize = 0.5f;
        [SerializeField, Range(0.0f, 5.0f)] private float farSizeExtra = 1.5f;
        [SerializeField] private Transform forceFieldContainer;
        [SerializeField] private ParticleSystemForceField forceFieldRange;
        [SerializeField] private ParticleSystemForceField forceFieldVortexCore;
        [SerializeField] private ParticleSystemForceField forceFieldVortexFar;

        private void Update()
        {
            float distanceToTravel = Vector3.Distance(
                particleSystem.transform.position, target.position);
            distanceToTravel = Mathf.Abs(distanceToTravel - coreSize);

            distanceToTravel += Mathf.PI * 2.0f * coreSize;
            
            ParticleSystem.MainModule mainModule = particleSystem.main;
            
            ParticleSystem.MinMaxCurve startLifetime = mainModule.startLifetime;
            startLifetime.constantMax = distanceToTravel * lifetimePerDistance + lifetimeExtra;
            startLifetime.constantMin = startLifetime.constantMax * lifetimeNormalizedMin;
            mainModule.startLifetime = startLifetime;

            forceFieldRange.startRange = coreSize;
            forceFieldVortexCore.endRange = coreSize;
            forceFieldVortexFar.endRange = coreSize + farSizeExtra;
        }

        private void OnDrawGizmos()
        {
            if (forceFieldContainer != null)
            {
                Gizmos.color = Color.white;
                Gizmos.DrawWireSphere(forceFieldContainer.position, coreSize);
                Gizmos.color = Color.magenta;
                Gizmos.DrawWireSphere(forceFieldContainer.position, coreSize + farSizeExtra);
            }
        }
    }
}

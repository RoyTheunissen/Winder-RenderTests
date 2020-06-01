using UnityEngine;

namespace RoyTheunissen.Winder.Rendering
{
    /// <summary>
    /// Attracts particles for the hand-drawn winding effects.
    /// </summary>
    public sealed class WindingParticlesAttractor : MonoBehaviour 
    {
        [Header("Settings")]
        [SerializeField, Range(0.5f, 5.0f)] private float coreSize = 0.5f;
        public float CoreSize => coreSize * Scale;

        [SerializeField, Range(0.0f, 5.0f)] private float farSizeExtra = 1.5f;

        private float FarSizeExtra => farSizeExtra / Scale;
        
        [Header("Dependencies")]
        [SerializeField] private ParticleSystemForceField forceFieldRange;
        [SerializeField] private ParticleSystemForceField forceFieldVortexCore;
        [SerializeField] private ParticleSystemForceField forceFieldVortexFar;
        
        private float Scale => transform.lossyScale.y;

        private void Update()
        {
            forceFieldRange.startRange = coreSize;
            forceFieldVortexCore.endRange = coreSize;
            forceFieldVortexFar.endRange = coreSize + FarSizeExtra;
        }

        public void ApplyForceFieldsToParticles(ParticleSystem.ExternalForcesModule externalForces)
        {
            externalForces.AddInfluence(forceFieldRange);
            externalForces.AddInfluence(forceFieldVortexCore);
            externalForces.AddInfluence(forceFieldVortexFar);
        }

        private void OnDrawGizmos()
        {
            Gizmos.color = Color.white;
            Gizmos.DrawWireSphere(transform.position, CoreSize);
            Gizmos.color = Color.magenta;
            Gizmos.DrawWireSphere(transform.position, CoreSize + farSizeExtra);
        }
    }
}

using UnityEngine;

namespace RoyTheunissen.Winder.Rendering
{
    /// <summary>
    /// Emits particles for the hand-drawn winding effects.
    /// </summary>
    public sealed class WindingParticlesEmitter : MonoBehaviour
    {
        [SerializeField] private new ParticleSystem particleSystem;

        [Space]
        [SerializeField] private float lifetimeNormalizedMin = 0.4f;
        [SerializeField] private float lifetimePerDistance = 4;
        [SerializeField] private float lifetimeExtra = 1;
        
        [Space]
        [SerializeField] private WindingParticlesAttractor attractor;

        private WindingParticlesAttractor attractorForceFieldsLastApplied;
        
        private float CoreSize => attractor == null ? 0.0f : attractor.CoreSize;

        private void Update()
        {
            float distanceToTravel = attractor == null ? 0.0f : Vector3.Distance(
                particleSystem.transform.position, attractor.transform.position);
            distanceToTravel = Mathf.Abs(distanceToTravel - CoreSize);

            distanceToTravel += Mathf.PI * 2.0f * CoreSize;
            
            ParticleSystem.MainModule mainModule = particleSystem.main;
            
            ParticleSystem.MinMaxCurve startLifetime = mainModule.startLifetime;
            startLifetime.constantMax = distanceToTravel * lifetimePerDistance + lifetimeExtra;
            startLifetime.constantMin = startLifetime.constantMax * lifetimeNormalizedMin;
            mainModule.startLifetime = startLifetime;

            UpdateAttractorForceFields();
        }

        private void UpdateAttractorForceFields()
        {
            if (attractorForceFieldsLastApplied == attractor)
                return;
            
            ParticleSystem.ExternalForcesModule externalForces = particleSystem.externalForces;

            if (attractorForceFieldsLastApplied != null)
                externalForces.RemoveAllInfluences();

            if (attractor != null)
                attractor.ApplyForceFieldsToParticles(externalForces);
            
            attractorForceFieldsLastApplied = attractor;
        }
    }
}

using UnityEngine;

public class Rotator : MonoBehaviour
{
    [SerializeField] private Vector3 speed = Vector3.up * 90;

    private void Update()
    {
        transform.eulerAngles += speed * Time.deltaTime;
    }
}

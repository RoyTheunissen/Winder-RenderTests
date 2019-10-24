using UnityEngine;

public class LightRotator : MonoBehaviour
{
    [SerializeField] private float speed = 90;

    private void Update()
    {
        transform.eulerAngles += Vector3.up * Time.deltaTime * speed;
    }
}

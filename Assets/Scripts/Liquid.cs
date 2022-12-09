using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class Liquid : MonoBehaviour
{
    [SerializeField]
    float maxWobble = 0.03f;

    [SerializeField]
    float wobbleSpeed = 1f;

    [Range(-0.25f, 1.25f)]
    public float fillAmount = 0.5f;

    [SerializeField]
    float recoverAmt = 1f;

    [SerializeField]
    Mesh mesh;

    Renderer rend;
	
    float wobbleX;
    float wobbleZ;
	
    float addWobbleX;
    float addWobbleZ;
    float time = 0.5f;
	
    Vector3 oldPos;
    Quaternion oldRot;

    //Use this for initialization
    void Start()
    {
        rend = GetComponent<Renderer>();
    }

    private void OnValidate()
    {
        if (mesh == null)
        {
            mesh = GetComponent<MeshFilter>().sharedMesh;
        }
    }

    private void Update()
    {
        time += Time.deltaTime;
        // decrease wobble over time
        addWobbleX = Mathf.Lerp(addWobbleX, 0, Time.deltaTime * (recoverAmt));
        addWobbleZ = Mathf.Lerp(addWobbleZ, 0, Time.deltaTime * (recoverAmt));

        //Make a sine wave of the decreasing wobble
        float intensity = 2 * Mathf.PI * wobbleSpeed;
        wobbleX = addWobbleX * Mathf.Sin(intensity * time);
        wobbleZ = addWobbleZ * Mathf.Sin(intensity * time);

        //Send wobble to the shader
        rend.sharedMaterial.SetFloat("_WobbleX", wobbleX);
        rend.sharedMaterial.SetFloat("_WobbleZ", wobbleZ);

        //Calculate velocity (distance/time)
        Vector3 velocity = (oldPos - transform.position) / Time.deltaTime;
        Vector3 angularVelocity = GetAngularVelocity(oldRot, transform.rotation);

        //Add clamped velocity to wobble
        addWobbleX += Mathf.Clamp((velocity.x + angularVelocity.z) * maxWobble, -maxWobble, maxWobble);
        addWobbleZ += Mathf.Clamp((velocity.z + angularVelocity.x) * maxWobble, -maxWobble, maxWobble);

        // keep last position
        oldPos = transform.position;
        oldRot = transform.rotation;

        //Set fill amount
        Vector3 worldPos = transform.TransformPoint(new Vector3(mesh.bounds.center.x, mesh.bounds.center.y, mesh.bounds.center.z));
        Vector3 finalFillAmt = worldPos - transform.position - new Vector3(0, -fillAmount + 1, 0);
		
		//Send fill to shader
        rend.sharedMaterial.SetVector("_FillAmount", finalFillAmt);
    }

	//This portion of code was used from this unity forum post
    //https://forum.unity.com/threads/manually-calculate-angular-velocity-of-gameobject.289462/#post-4302796
    Vector3 GetAngularVelocity(Quaternion foreLastFrameRotation, Quaternion lastFrameRotation)
    {
        var q = lastFrameRotation * Quaternion.Inverse(foreLastFrameRotation);
        // You may want to increase this closer to 1 if you want to handle very small rotations.
        // Beware, if it is too close to one your answer will be Nan
        if (Mathf.Abs(q.w) > 1023.5f / 1024.0f)
            return new Vector3(0, 0, 0);
        float gain;
        // handle negatives, we could just flip it but this is faster
        if (q.w < 0.0f)
        {
            var angle = Mathf.Acos(-q.w);
            gain = -2.0f * angle / (Mathf.Sin(angle) * Time.deltaTime);
        }
        else
        {
            var angle = Mathf.Acos(q.w);
            gain = 2.0f * angle / (Mathf.Sin(angle) * Time.deltaTime);
        }
        return new Vector3(q.x * gain, q.y * gain, q.z * gain);
    }
	
	
    Vector3 GetLowestPoint()
    {
        float lowestY = float.MaxValue;
        Vector3 lowestVert = Vector3.zero;
        Vector3[] vertices = mesh.vertices;

        for (int i = 0; i < vertices.Length; i++)
        {
            Vector3 position = transform.TransformPoint(vertices[i]);
            if (position.y < lowestY)
            {
                lowestY = position.y;
                lowestVert = position;
            }
        }
        return lowestVert;
    }
}
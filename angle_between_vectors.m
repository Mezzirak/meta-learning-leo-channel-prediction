function angle = angle_between_vectors(v1, v2)
    dot_product = dot(v1, v2);
    magnitudes = norm(v1) * norm(v2);
    if magnitudes ~= 0
        angle = acos(dot_product / magnitudes);
    else
        angle = 0;
    end
end